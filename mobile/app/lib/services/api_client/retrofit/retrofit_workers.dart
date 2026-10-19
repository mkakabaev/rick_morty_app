import 'dart:convert';

import 'package:core/core.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' as foundation;

//
// The collection of utils to make Dio->Retrofit serialize/deserialize DTOs efficiently
// The main idea is to use single worker for all the operations and avoid passing data between Dio and Retrofit
// isolates. Current Retrofit implementation can work only with Map<String, dynamic> objects, so we mimic
// JSON serialization/deserialization by wrapping the data into a single-entry Map<String, dynamic> and processing
// it in Retrofit worker (See )
//

///
/// Transformer to pass background processing to Retrofit API calls. This way
/// we will try to avoid passing data between Dio & Retrofit isolates and do all
/// the work in the intercepted compute() function at Retrofit level.
/// We can't just pass the data as it is because Retrofit (currently) can work only with
/// [Map<String, dynamic>] objects, so we will create a fake JSON object and pass as is
///
class RetrofitWorkerBridgeTransformer extends SyncTransformer {
  RetrofitWorkerBridgeTransformer() : super(jsonDecodeCallback: _string2Map, jsonEncodeCallback: _map2String);
}

Map<String, dynamic> _string2Map(String jsonText) => <String, dynamic>{'j': jsonText};
String _map2String(Object jsonMap) => (jsonMap as Map)['j'] as String;

/// Unwraps [RetrofitWorkerBridgeTransformer] response data back to decoded JSON.
///
/// Success and error responses alike arrive as `{'j': '<raw json string>'}`.
/// Returns [data] unchanged when it is already a normal decoded value.
Object? unwrapBridgedResponseData(Object? data) {
  if (data is Map) {
    return jsonDecode(_map2String(data));
  }
  return data;
}

/*
////
//// Here is an example of classic background isolate usage which is based on Worker (works
//// better than compute() )
////
class DioBackgroundTransformer extends SyncTransformer {
  late final Future<Worker> worker;
  Worker? _resolvedWorker;

  DioBackgroundTransformer() : super(jsonDecodeCallback: (_) => null) {
    worker = Worker.spawn(name: 'DioDecoderWorker');
    jsonDecodeCallback = (jsonText) async {
      final w = _resolvedWorker ??= await worker;
      return w.process(jsonDecode, jsonText);
    };
  }
}
*/

// Just a sample of how to split tasks between workers.
// We can use different workers for serialization and deserialization. More fine control can be
// achieved by analyzing the message type.

class _WorkerHolder {
  final Future<Worker> futureWorker;
  Worker? resolvedWorker;

  _WorkerHolder(String name) : futureWorker = Worker.spawn(name: name);
}

final _decoderWorker = _WorkerHolder('RetrofitDecoderWorker');
final _encoderWorker = _WorkerHolder('RetrofitEncoderWorker');

// Upd: not necessary anymore// This is to call in app's bootstrapping() to warm up the workers
// Future<void> initApiWorkers() async {
//   final _ = await Future.wait([_decoderWorker.futureWorker, _encoderWorker.futureWorker]);
// }

///
/// Overridden compute() function to be used by Retrofit API calls. As of now this is the only way
/// to set up external handler. Of course this should be exposed only to [RestClient] and Retrofit
///
/// This is used both for serialization and deserialization. To distinguish the behavior we just perform
/// a simple type check. If the message is a [Map<String, dynamic>] we assume it's a deserialization.
///
/// @param callback - the original serializeT/deserializeT used by Retrofit
//
Future<R> compute<M, R>(foundation.ComputeCallback<M, R> callback, M message) async {
  // message is either result of _wrapJsonString2Map or _unwrapJsonStringFromMap. So we can detect if the
  // operation is related to serialization or deserialization

  // if the  message if it's a Map<String, dynamic>
  if (message is Map<String, dynamic>) {
    final stopwatch = RickMortyStopwatch();
    final worker = _decoderWorker.resolvedWorker ??= await _decoderWorker.futureWorker;
    final result = await worker.process(_DeserializationRequest(data: message, wrapToDtoFactory: callback));
    stopwatch.stop("RETROFIT DESERIALIZE: ${result.runtimeType}, max active requests: ${worker.maxActiveRequests}");
    return result;
  }

  // Serialization otherwise
  {
    final stopwatch = RickMortyStopwatch();
    final worker = _encoderWorker.resolvedWorker ??= await _encoderWorker.futureWorker;
    final result = await worker.process(_SerializeDtoRequest(data: message, dtoToWrapFactory: callback));
    stopwatch.stop("RETROFIT SERIALIZE: ${message.runtimeType}, max active requests: ${worker.maxActiveRequests}");
    return result;
  }
}

/// Used to sending: Takes DTO and returned { 'j': 'json string' }
class _SerializeDtoRequest<R, M> extends WorkerRequest<M, R> {
  final foundation.ComputeCallback<M, R> dtoToWrapFactory;

  _SerializeDtoRequest({required super.data, required this.dtoToWrapFactory});

  @override
  Future<R> handler() async {
    final jsonMap = dtoToWrapFactory(data);
    final encodedString = jsonEncode(jsonMap is Future ? await jsonMap : jsonMap);
    return _string2Map(encodedString) as R;
  }
}

/// Used to receiving: Takes { 'j': 'json string' }, returns DTO (or throws ErrorDto if it's present)
class _DeserializationRequest<R, M> extends WorkerRequest<M, R> {
  final foundation.ComputeCallback<M, R> wrapToDtoFactory;

  _DeserializationRequest({required super.data, required this.wrapToDtoFactory});

  @override
  Future<R> handler() async {
    final jsonText = _map2String(data as Map);
    final decodedJson = jsonDecode(jsonText);
    final result = wrapToDtoFactory(decodedJson as M);
    return result is Future ? await result : result;
  }
}
