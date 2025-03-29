template<typename T>
class PromiseResolver;

template<typename T1, typename T2, typename T3>
class TypedPromiseCallbackWithoutPrevResult {
public: // types
    typedef void (*CallbackWithoutPrevResult)(PromiseResolver<T2>*);

public: // fields
    CallbackWithoutPrevResult callback;

public: // TypedPromiseCallbackWithoutPrevResult()
    TypedPromiseCallbackWithoutPrevResult(CallbackWithoutPrevResult c): callback(c) {};
};

template<typename T1, typename T2, typename T3>
class TypedPromiseCallbackWithoutParam {
public: // types
    typedef void (*CallbackWithoutParam)(PromiseResolver<T2>*, T1);

public: // fields
    CallbackWithoutParam callback;

public: // TypedPromiseCallbackWithoutParam()
    TypedPromiseCallbackWithoutParam(CallbackWithoutParam c): callback(c) {};
};

template<typename T1, typename T2, typename T3>
class TypedPromiseCallbackWithParam {
public: // types
    typedef void (*CallbackWithParam)(PromiseResolver<T2>*, T1, T3);

public: // fields
    CallbackWithParam callback;

public: // TypedPromiseCallbackWithParam()
    TypedPromiseCallbackWithParam(CallbackWithParam c): callback(c) {};
};

class BasePromiseCallback {
public: // BasePromiseCallback()
    BasePromiseCallback() {};

public: // .execute()
    void execute() {};
};

template<typename T>
class TypedPromiseCallback: public BasePromiseCallback {
public: // types
    typedef void (*CancelHandlerWithoutParam)();
    typedef void (*CancelHandlerWithParam)(T);

public: // fields
    CancelHandlerWithoutParam callbackWithoutParam;
    CancelHandlerWithParam callbackWithParam;
    bool _withParam;
    T _param;

public: // TypedPromiseCallback()
    TypedPromiseCallback(CancelHandlerWithoutParam c): BasePromiseCallback(), callbackWithoutParam(c), _withParam(false) {};
    TypedPromiseCallback(CancelHandlerWithParam c): BasePromiseCallback(), callbackWithParam(c), _withParam(true) {};

public: // .execute()
    void execute() {
        if (this._withParam) {
            callbackWithParam(_param);
        } else {
            callbackWithoutParam();
        }
    };
};
