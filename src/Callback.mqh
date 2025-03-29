template<typename T>
class PromiseResolver;

template<typename T1, typename T2, typename T3>
class TypedPromiseCallbackWithoutPrevResult {
public:
    typedef void (*CallbackWithoutPrevResult)(PromiseResolver<T2>*);
    CallbackWithoutPrevResult callback;
    TypedPromiseCallbackWithoutPrevResult(CallbackWithoutPrevResult c): callback(c) {};
};
template<typename T1, typename T2, typename T3>
class TypedPromiseCallbackWithoutParam {
public:
    typedef void (*CallbackWithoutParam)(PromiseResolver<T2>*, T1);
    CallbackWithoutParam callback;
    TypedPromiseCallbackWithoutParam(CallbackWithoutParam c): callback(c) {};
};
template<typename T1, typename T2, typename T3>
class TypedPromiseCallbackWithParam {
public:
    typedef void (*CallbackWithParam)(PromiseResolver<T2>*, T1, T3);
    CallbackWithParam callback;
    TypedPromiseCallbackWithParam(CallbackWithParam c): callback(c) {};
};

class BasePromiseCallback {
public:
    BasePromiseCallback() {};
    void execute() {};
};

template<typename T>
class TypedPromiseCallback: public BasePromiseCallback {
public:
    typedef void (*CancelHandlerWithoutParam)();
    typedef void (*CancelHandlerWithParam)(T);

    CancelHandlerWithoutParam callbackWithoutParam;
    CancelHandlerWithParam callbackWithParam;
    bool _withParam;
    T _param;

    TypedPromiseCallback(CancelHandlerWithoutParam c): BasePromiseCallback(), callbackWithoutParam(c), _withParam(false) {};
    TypedPromiseCallback(CancelHandlerWithParam c): BasePromiseCallback(), callbackWithParam(c), _withParam(true) {};

    void execute() {
        if (this._withParam) {
            callbackWithParam(_param);
        } else {
            callbackWithoutParam();
        }
    };
};
