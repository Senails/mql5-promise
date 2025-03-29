class Promise: public TypedPromise<string, string, string> {
public: // Promise()
    Promise(CallbackWithoutPrevResult call): TypedPromise<string, string, string>(call) {};
    Promise(CallbackWithoutParam call): TypedPromise<string, string, string>(call) {};
    Promise(CallbackWithParam call, string p): TypedPromise<string, string, string>(call, p) {};

public: // .try()
    static TypedPromise<string, string, string>* try(CallbackWithoutPrevResult call) {
        return new Promise(call);
    };
    static TypedPromise<string, string, string>* try(CallbackWithoutParam call) {
        return new Promise(call);
    };
    static TypedPromise<string, string, string>* try(CallbackWithParam call, string p) {
        return new Promise(call, p);
    };

    template<typename T1, typename T2, typename T3>
    static TypedPromise<T1, T2, T3>* try(TypedPromiseCallbackWithoutPrevResult<T1, T2, T3>* call) {
        return new TypedPromise<T1, T2, T3>(call);
    };
    template<typename T1, typename T2, typename T3>
    static TypedPromise<T1, T2, T3>* try(TypedPromiseCallbackWithoutParam<T1, T2, T3>* call) {
        return new TypedPromise<T1, T2, T3>(call);
    };
    template<typename T1, typename T2, typename T3>
    static TypedPromise<T1, T2, T3>* try(TypedPromiseCallbackWithParam<T1, T2, T3>* call, T3 param) {
        return new TypedPromise<T1, T2, T3>(call, param);
    };

public: // .resolve()
    template<typename T2>
    static TypedPromise<string, T2, T2>* resolve(T2 param) {
        return new TypedPromise<string, T2, T2>(TypedPromise<string, T2, T2>::_resolveParamCallback, param);
    };
    static TypedPromise<string, string, string>* resolve() {
        return new Promise(Promise::_resolveParamCallback, "");
    };

public: // .reject()
    static TypedPromise<string, string, string>* reject(string message = "") {
        return new Promise(Promise::_rejectParamCallback, "");
    };
};
