// T1 - prev promise return type
// T2 - promise return type
// T3 - param type
template<typename T1, typename T2, typename T3>
class TypedPromise: public BasePromise {
private: // types
    // callback for current promise
    typedef void (*CallbackWithoutPrevResult)(PromiseResolver<T2>*);
    typedef void (*CallbackWithoutParam)(PromiseResolver<T2>*, T1);
    typedef void (*CallbackWithParam)(PromiseResolver<T2>*, T1, T3);

    // default callback for then promise
    typedef void (*ThenCallbackWithoutPrevResult)(PromiseResolver<string>*);
    typedef void (*ThenCallbackWithoutParam)(PromiseResolver<string>*, T2);
    typedef void (*ThenCallbackWithParam)(PromiseResolver<string>*, T2, string);

    // default callback for catch promise
    typedef void (*CatchCallbackWithoutPrevResult)(PromiseResolver<T2>*);
    typedef void (*CatchCallbackWithoutParam)(PromiseResolver<T2>*, string);
    typedef void (*CatchCallbackWithParam)(PromiseResolver<T2>*, string, string);

    // default callback for finally promise
    typedef void (*FinallyCallbackWithoutPrevResult)(PromiseResolver<string>*);
    typedef void (*FinallyCallbackWithoutParam)(PromiseResolver<string>*, string);
    typedef void (*FinallyCallbackWithParam)(PromiseResolver<string>*, string, string);

    typedef void (*SimpleCallbackWithoutParam)();
    typedef void (*SimpleCallbackWithStringParam)(string);
    typedef void (*SimpleCallbackWithTypedParam)(T3);
    
public: // TypedPromise::promiseCallback()
    static TypedPromiseCallbackWithoutPrevResult<T1,T2,T3>* promiseCallback(CallbackWithoutPrevResult call) {
        return new TypedPromiseCallbackWithoutPrevResult<T1,T2,T3>(call);
    };
    static TypedPromiseCallbackWithoutParam<T1,T2,T3>* promiseCallback(CallbackWithoutParam call) {
        return new TypedPromiseCallbackWithoutParam<T1,T2,T3>(call);
    };
    static TypedPromiseCallbackWithParam<T1,T2,T3>* promiseCallback(CallbackWithParam call) {
        return new TypedPromiseCallbackWithParam<T1,T2,T3>(call);
    };

public: // TypedPromise::callbackWithParam()
    static TypedPromiseCallback<string>* callbackWithParam(SimpleCallbackWithoutParam call) {
        return new TypedPromiseCallback<string>(call);
    };
    static TypedPromiseCallback<T3>* callbackWithParam(SimpleCallbackWithTypedParam call) {
        return new TypedPromiseCallback<T3>(call);
    };

private: // fields
    PromiseResolver<T2>* resolver;
    PromiseResolver<T1>* parentResolver;
    BasePromiseResolver* baseParentResolver;
    PromiseResolver<T2>* parentResolverWithTheSameType;

    TypedPromiseCallbackWithParam<T1, T2, T3>* execCallbackWithParam;
    TypedPromiseCallbackWithoutParam<T1, T2, T3>* execCallbackWithoutParam;
    TypedPromiseCallbackWithoutPrevResult<T1, T2, T3>* execCallbackWithoutPrevResult;

    TypedPromiseCallbackWithParam<string, T2, T3>* simpleCallbackWithParam;
    TypedPromiseCallbackWithoutParam<string, T2, T3>* simpleCallbackWithoutParam;
    TypedPromiseCallbackWithoutPrevResult<string, T2, T3>* simpleCallbackWithoutPrevResult;

    bool withoutPrevResult;
    bool withoutParam;
    T3 param;

public: // TypedPromise()
    TypedPromise(CallbackWithoutPrevResult call): BasePromise(), execCallbackWithoutPrevResult(TypedPromise::promiseCallback(call)), withoutParam(true), withoutPrevResult(true)                    { this.init(); };
    TypedPromise(CallbackWithoutParam call): BasePromise(), execCallbackWithoutParam(TypedPromise::promiseCallback(call)), withoutParam(true), withoutPrevResult(false)                             { this.init(); };
    TypedPromise(CallbackWithParam call, T3 param_): BasePromise(), execCallbackWithParam(TypedPromise::promiseCallback(call)), param(param_), withoutParam(false), withoutPrevResult(false)        { this.init(); };

    TypedPromise(TypedPromiseCallbackWithoutPrevResult<T1, T2, T3>* call): BasePromise(), execCallbackWithoutPrevResult(call), withoutParam(true), withoutPrevResult(true)                          { this.init(); };
    TypedPromise(TypedPromiseCallbackWithoutParam<T1, T2, T3>* call): BasePromise(), execCallbackWithoutParam(call), withoutParam(true), withoutPrevResult(false)                                   { this.init(); };
    TypedPromise(TypedPromiseCallbackWithParam<T1, T2, T3>* call, T3 param_): BasePromise(), execCallbackWithParam(call), param(param_), withoutParam(false), withoutPrevResult(false)              { this.init(); };

public: // TypedPromise::_createThenChildPromise()
    static TypedPromise* _createThenChildPromise(TypedPromiseCallbackWithoutPrevResult<T1, T2, T3>* call, PromiseResolver<T1>* pResolver)             { return new TypedPromise(call, pResolver); };
    static TypedPromise* _createThenChildPromise(TypedPromiseCallbackWithoutParam<T1, T2, T3>* call, PromiseResolver<T1>* pResolver)                  { return new TypedPromise(call, pResolver); };
    static TypedPromise* _createThenChildPromise(TypedPromiseCallbackWithParam<T1, T2, T3>* call, T3 param_, PromiseResolver<T1>* pResolver)          { return new TypedPromise(call, param_, pResolver); };

public: // TypedPromise::_createCatchChildPromise()
    static TypedPromise* _createCatchChildPromise(TypedPromiseCallbackWithoutPrevResult<string, T2, T3>* call, PromiseResolver<T2>* pResolver)        { return new TypedPromise(call, pResolver, true); };
    static TypedPromise* _createCatchChildPromise(TypedPromiseCallbackWithoutParam<string, T2, T3>* call, PromiseResolver<T2>* pResolver)             { return new TypedPromise(call, pResolver, true); };
    static TypedPromise* _createCatchChildPromise(TypedPromiseCallbackWithParam<string, T2, T3>* call, T3 param_, PromiseResolver<T2>* pResolver)     { return new TypedPromise(call, param_, pResolver, true); };

public: // TypedPromise::_createFinallyChildPromise()
    static TypedPromise* _createFinallyChildPromise(TypedPromiseCallbackWithoutPrevResult<string, T2, T3>* call, BasePromiseResolver* pResolver)      { return new TypedPromise(call, pResolver, true, true); };
    static TypedPromise* _createFinallyChildPromise(TypedPromiseCallbackWithoutParam<string, T2, T3>* call, BasePromiseResolver* pResolver)           { return new TypedPromise(call, pResolver, true, true); };
    static TypedPromise* _createFinallyChildPromise(TypedPromiseCallbackWithParam<string, T2, T3>* call, T3 param_, BasePromiseResolver* pResolver)   { return new TypedPromise(call, param_, pResolver, true, true); };

private: // TypedPromise()
    TypedPromise(TypedPromiseCallbackWithoutPrevResult<T1, T2, T3>* call, PromiseResolver<T1>* pResolver): BasePromise(pResolver._basePromise, ThenType), execCallbackWithoutPrevResult(call), withoutParam(true), withoutPrevResult(true) , parentResolver(pResolver)                                              { this.init(); };
    TypedPromise(TypedPromiseCallbackWithoutParam<T1, T2, T3>* call, PromiseResolver<T1>* pResolver): BasePromise(pResolver._basePromise, ThenType), execCallbackWithoutParam(call), withoutParam(true), withoutPrevResult(false), parentResolver(pResolver)                                                        { this.init(); };
    TypedPromise(TypedPromiseCallbackWithParam<T1, T2, T3>* call, T3 param_, PromiseResolver<T1>* pResolver): BasePromise(pResolver._basePromise, ThenType), execCallbackWithParam(call), param(param_), withoutParam(false), withoutPrevResult(false), parentResolver(pResolver)                                   { this.init(); };

    TypedPromise(TypedPromiseCallbackWithoutPrevResult<string, T2, T3>* call, PromiseResolver<T2>* pResolver, bool _): BasePromise(pResolver._basePromise, CatchType), simpleCallbackWithoutPrevResult(call), withoutParam(true), withoutPrevResult(true), parentResolverWithTheSameType(pResolver)                 { this.init(); };
    TypedPromise(TypedPromiseCallbackWithoutParam<string, T2, T3>* call, PromiseResolver<T2>* pResolver, bool _): BasePromise(pResolver._basePromise, CatchType), simpleCallbackWithoutParam(call), withoutParam(true), withoutPrevResult(false), parentResolverWithTheSameType(pResolver)                          { this.init(); };
    TypedPromise(TypedPromiseCallbackWithParam<string, T2, T3>* call, T3 param_, PromiseResolver<T2>* pResolver, bool _): BasePromise(pResolver._basePromise, CatchType), simpleCallbackWithParam(call), param(param_), withoutParam(false), withoutPrevResult(false), parentResolverWithTheSameType(pResolver)     { this.init(); };

    TypedPromise(TypedPromiseCallbackWithoutPrevResult<string, T2, T3>* call, BasePromiseResolver* pResolver, bool _, bool __): BasePromise(pResolver._basePromise, FinallyType), simpleCallbackWithoutPrevResult(call), withoutParam(true), withoutPrevResult(true), baseParentResolver(pResolver)                 { this.init(); };
    TypedPromise(TypedPromiseCallbackWithoutParam<string, T2, T3>* call, BasePromiseResolver* pResolver, bool _, bool __): BasePromise(pResolver._basePromise, FinallyType), simpleCallbackWithoutParam(call), withoutParam(true), withoutPrevResult(false), baseParentResolver(pResolver)                          { this.init(); };
    TypedPromise(TypedPromiseCallbackWithParam<string, T2, T3>* call, T3 param_, BasePromiseResolver* pResolver, bool _, bool __): BasePromise(pResolver._basePromise, FinallyType), simpleCallbackWithParam(call), param(param_), withoutParam(false), withoutPrevResult(false), baseParentResolver(pResolver)     { this.init(); };

public: // .then()
    TypedPromise<T2, string, string>* then(ThenCallbackWithoutPrevResult call) {
        return this.then(TypedPromise<T2,string,string>::promiseCallback(call));
    };
    TypedPromise<T2, string, string>* then(ThenCallbackWithoutParam call) {
        return this.then(TypedPromise<T2,string,string>::promiseCallback(call));
    };
    TypedPromise<T2, string, string>* then(ThenCallbackWithParam call, string param_) {
        return this.then(TypedPromise<T2,string,string>::promiseCallback(call), param_);
    };

    template<typename TT2, typename TT3>
    TypedPromise<T2, TT2, TT3>* then(TypedPromiseCallbackWithoutPrevResult<T2, TT2, TT3>* call) {
        return this._then(TypedPromise<T2, TT2, TT3>::_createThenChildPromise(call, this.resolver));
    };
    template<typename TT2, typename TT3>
    TypedPromise<T2, TT2, TT3>* then(TypedPromiseCallbackWithoutParam<T2, TT2, TT3>* call) {
        return this._then(TypedPromise<T2, TT2, TT3>::_createThenChildPromise(call, this.resolver));
    };
    template<typename TT2, typename TT3>
    TypedPromise<T2, TT2, TT3>* then(TypedPromiseCallbackWithParam<T2, TT2, TT3>* call, TT3 param_) {
        return this._then(TypedPromise<T2, TT2, TT3>::_createThenChildPromise(call, param_, this.resolver));
    };
    
public: // .tap()
    TypedPromise<string, T2, PromiseResolver<T2>*>* tap(ThenCallbackWithoutPrevResult call) {
        return this.tap(TypedPromise<T2, string, string>::promiseCallback(call));
    };
    TypedPromise<string, T2, PromiseResolver<T2>*>* tap(ThenCallbackWithoutParam call) {
        return this.tap(TypedPromise<T2, string, string>::promiseCallback(call));
    };
    TypedPromise<string, T2, PromiseResolver<T2>*>* tap(ThenCallbackWithParam call, string param_) {
        return this.tap(TypedPromise<T2, string, string>::promiseCallback(call), param_);
    };

    template<typename TT2, typename TT3>
    TypedPromise<TT2, T2, PromiseResolver<T2>*>* tap(TypedPromiseCallbackWithoutPrevResult<T2, TT2, TT3>* call) {
        return this.then(call).then(TypedPromise<TT2, T2, PromiseResolver<T2>*>::promiseCallback(TypedPromise<TT2, T2, PromiseResolver<T2>*>::_resolveResolverValue), this.resolver);
    };
    template<typename TT2, typename TT3>
    TypedPromise<TT2, T2, PromiseResolver<T2>*>* tap(TypedPromiseCallbackWithoutParam<T2, TT2, TT3>* call) {
        return this.then(call).then(TypedPromise<TT2, T2, PromiseResolver<T2>*>::promiseCallback(TypedPromise<TT2, T2, PromiseResolver<T2>*>::_resolveResolverValue), this.resolver);
    };
    template<typename TT2, typename TT3>
    TypedPromise<TT2, T2, PromiseResolver<T2>*>* tap(TypedPromiseCallbackWithParam<T2, TT2, TT3>* call, TT3 param_) {
        return this.then(call, param_).then(TypedPromise<TT2, T2, PromiseResolver<T2>*>::promiseCallback(TypedPromise<TT2, T2, PromiseResolver<T2>*>::_resolveResolverValue), this.resolver);
    };

    static void _resolveResolverValue(PromiseResolver<T2>* resolver, T1 prev, PromiseResolver<T2>* propResolver) {
        resolver.resolve(propResolver._value);
    };

public: // .catch()
    TypedPromise<string, T2, string>* catch(CatchCallbackWithoutPrevResult call) {
        return this.catch(TypedPromise<string, T2, string>::promiseCallback(call));
        };
    TypedPromise<string, T2, string>* catch(CatchCallbackWithoutParam call) {
        return this.catch(TypedPromise<string, T2, string>::promiseCallback(call));
    };
    TypedPromise<string, T2, string>* catch(CatchCallbackWithParam call, string param_) {
        return this.catch(TypedPromise<string, T2, string>::promiseCallback(call), param_);
    };

    template<typename TT3>
    TypedPromise<string, T2, TT3>* catch(TypedPromiseCallbackWithoutPrevResult<string, T2, TT3>* call) {
        return this._catch(TypedPromise<string, T2, TT3>::_createCatchChildPromise(call, this.resolver));
    };
    template<typename TT3>
    TypedPromise<string, T2, TT3>* catch(TypedPromiseCallbackWithoutParam<string, T2, TT3>* call) {
        return this._catch(TypedPromise<string, T2, TT3>::_createCatchChildPromise(call, this.resolver));
    };
    template<typename TT3>
    TypedPromise<string, T2, TT3>* catch(TypedPromiseCallbackWithParam<string, T2, TT3>* call, TT3 param_) {
        return this._catch(TypedPromise<string, T2, TT3>::_createCatchChildPromise(call, param_, this.resolver));
    };

public: // .tapCatch()
    TypedPromise<string, T2, PromiseResolver<T2>*>* tapCatch(CatchCallbackWithoutPrevResult call) {
        return this.tapCatch(TypedPromise<string, T2, string>::promiseCallback(call));
    };
    TypedPromise<string, T2, PromiseResolver<T2>*>* tapCatch(CatchCallbackWithoutParam call) {
        return this.tapCatch(TypedPromise<string, T2, string>::promiseCallback(call));
    };
    TypedPromise<string, T2, PromiseResolver<T2>*>* tapCatch(CatchCallbackWithParam call, string param_) {
        return this.tapCatch(TypedPromise<string, T2, string>::promiseCallback(call), param_);
    };

    template<typename TT3>
    TypedPromise<string, T2, PromiseResolver<T2>*>* tapCatch(TypedPromiseCallbackWithoutPrevResult<string, T2, TT3>* call) {
        return this.catch(call).finally(TypedPromise<string, T2, PromiseResolver<T2>*>::promiseCallback(TypedPromise::_rejectResolverValueIfNeeded), this.resolver);
    };
    template<typename TT3>
    TypedPromise<string, T2, PromiseResolver<T2>*>* tapCatch(TypedPromiseCallbackWithoutParam<string, T2, TT3>* call) {
        return this.catch(call).finally(TypedPromise<string, T2, PromiseResolver<T2>*>::promiseCallback(TypedPromise::_rejectResolverValueIfNeeded), this.resolver);
    };
    template<typename TT3>
    TypedPromise<string, T2, PromiseResolver<T2>*>* tapCatch(TypedPromiseCallbackWithParam<string, T2, TT3>* call, TT3 param_) {
        return this.catch(call, param_).finally(TypedPromise<string, T2, PromiseResolver<T2>*>::promiseCallback(TypedPromise::_rejectResolverValueIfNeeded), this.resolver);
    };

    static void _rejectResolverValueIfNeeded(PromiseResolver<T2>* resolver, string prev, PromiseResolver<T2>* propResolver) {
        if (propResolver._isRejected) {
            resolver.reject(propResolver._rejectValue);
        } else {
            resolver.resolve(propResolver._value);
        }
    };

public: // .finally()
    TypedPromise<string, string, string>* finally(FinallyCallbackWithoutPrevResult call) {
        return this.finally(TypedPromise<string,string,string>::promiseCallback(call));
    };
    TypedPromise<string, string, string>* finally(FinallyCallbackWithoutParam call) {
        return this.finally(TypedPromise<string,string,string>::promiseCallback(call));
    };
    TypedPromise<string, string, string>* finally(FinallyCallbackWithParam call, string param_) {
        return this.finally(TypedPromise<string,string,string>::promiseCallback(call), param_);
    };

    template<typename TT2, typename TT3>
    TypedPromise<string, TT2, TT3>* finally(TypedPromiseCallbackWithoutPrevResult<string, TT2, TT3>* call) {
        return this._finally(TypedPromise<string, TT2, TT3>::_createFinallyChildPromise(call, this.resolver));
    };
    template<typename TT2, typename TT3>
    TypedPromise<string, TT2, TT3>* finally(TypedPromiseCallbackWithoutParam<string, TT2, TT3>* call) {
        return this._finally(TypedPromise<string, TT2, TT3>::_createFinallyChildPromise(call, this.resolver));
    };
    template<typename TT2, typename TT3>
    TypedPromise<string, TT2, TT3>* finally(TypedPromiseCallbackWithParam<string, TT2, TT3>* call, TT3 param_) {
        return this._finally(TypedPromise<string, TT2, TT3>::_createFinallyChildPromise(call, param_, this.resolver));
    };

private: // .init()
    void init() {
        this.resolver = new PromiseResolver<T2>(&this);
        if (this.promiseChildType != NullType) return;

        this.parentResolver = new PromiseResolver<T1>(&this);
        this._thenExecuteResolve();
    };

private: // ._then()
    template<typename TT2, typename TT3>
    TypedPromise<T2, TT2, TT3>* _then(TypedPromise<T2, TT2, TT3>* childPromise) {
        if (this.promiseStatus == ResolvedState) {
            childPromise._thenExecuteResolve();
        } else if (this.promiseStatus == RejectedState) {
            childPromise._thenExecuteReject();
        } else if (this.promiseStatus == DeletedState) {
            childPromise._thenExecuteRejectWaitForDelete();
        }
        return childPromise;
    };

public: // _then executors
    void virtual _thenExecuteResolve() override {
        bool withoutPrevResult_ = this.withoutPrevResult;
        bool withoutParam_ = this.withoutParam;

        if (withoutPrevResult_) {
            this.execCallbackWithoutPrevResult.callback(this.resolver);
        } else if (withoutParam_) {
            this.execCallbackWithoutParam.callback(this.resolver, this.parentResolver._value);
        } else {
            this.execCallbackWithParam.callback(this.resolver, this.parentResolver._value, this.param);
        }
    };
    void virtual _thenExecuteReject() override {
        this.resolver.reject(this.parentResolver._rejectValue);
    };
    void virtual _thenExecuteRejectWaitForDelete() override {
        this.resolver.reject("The object is awaiting deletion");
    };

private: // ._catch()
    template<typename TT3>
    TypedPromise<string, T2, TT3>* _catch(TypedPromise<string, T2, TT3>* childPromise) {
        if (this.promiseStatus == ResolvedState) {
            childPromise._catchExecuteResolve();
        } else  if (this.promiseStatus == RejectedState) {
            childPromise._catchExecuteReject();
        } else  if (this.promiseStatus == DeletedState) {
            childPromise._catchExecuteRejectWaitForDelete();
        }
        return childPromise;
    };

public: // _catch executors
    void virtual _catchExecuteResolve() override {
        this.resolver.resolve(this.parentResolverWithTheSameType._value);
    };
    void virtual _catchExecuteReject() override {
        bool withoutPrevResult_ = this.withoutPrevResult;
        bool withoutParam_ = this.withoutParam;

        if (withoutPrevResult_) {
            this.simpleCallbackWithoutPrevResult.callback(this.resolver);
        } else if (withoutParam_) {
            this.simpleCallbackWithoutParam.callback(this.resolver, this.parentResolverWithTheSameType._rejectValue);
        } else {
            this.simpleCallbackWithParam.callback(this.resolver, this.parentResolverWithTheSameType._rejectValue, this.param);
        }
    };
    void virtual _catchExecuteRejectWaitForDelete() override {
        bool withoutPrevResult_ = this.withoutPrevResult;
        bool withoutParam_ = this.withoutParam;

        if (withoutPrevResult_) {
            this.simpleCallbackWithoutPrevResult.callback(this.resolver);
        } else if (withoutParam_) {
            this.simpleCallbackWithoutParam.callback(this.resolver, "The object is awaiting deletion");
        } else {
            this.simpleCallbackWithParam.callback(this.resolver, "The object is awaiting deletion", this.param);
        }
    };

private: // ._finally()
    template<typename TT2, typename TT3>
    TypedPromise<string, TT2, TT3>* _finally(TypedPromise<string, TT2, TT3>* childPromise) {
        if (this.promiseStatus == ResolvedState) {
            childPromise._finallyExecuteResolve();
        } else if (this.promiseStatus == RejectedState) {
            childPromise._finallyExecuteResolve();
        } else if (this.promiseStatus == DeletedState) {
            childPromise._finallyExecuteResolve();
        }
        return childPromise;
    };

public: // _finally executors
    void virtual _finallyExecuteResolve() override {
        bool withoutPrevResult_ = this.withoutPrevResult;
        bool withoutParam_ = this.withoutParam;

        if (withoutPrevResult_) {
            this.simpleCallbackWithoutPrevResult.callback(this.resolver);
        } else if (withoutParam_) {
            this.simpleCallbackWithoutParam.callback(this.resolver, "");
        } else {
            this.simpleCallbackWithParam.callback(this.resolver, "", this.param);
        }
    };

public: // ._resolveHandler()
    void virtual _resolveHandler() override {
        if (this.promiseStatus == DeletedState) return;
        this.promiseStatus = ResolvedState;

        for (int i = 0; i < ArraySize(this.childPromises); i++) {
            BasePromise* childPromise = this.childPromises[i];
            PromiseChildType childTyp = childPromise.promiseChildType;

            if (childTyp == ThenType) childPromise._thenExecuteResolve();
            if (childTyp == CatchType) childPromise._catchExecuteResolve();
            if (childTyp == FinallyType) childPromise._finallyExecuteResolve(); 
        }
    };
public: // ._rejectHandler()
    void virtual _rejectHandler() override {
        if (this.promiseStatus == DeletedState) return;
        this.promiseStatus = RejectedState;

        for (int i = 0; i < ArraySize(this.childPromises); i++) {
            BasePromise* childPromise = this.childPromises[i];
            PromiseChildType childTyp = childPromise.promiseChildType;

            if (childTyp == ThenType) childPromise._thenExecuteReject();
            if (childTyp == CatchType) childPromise._catchExecuteReject();
            if (childTyp == FinallyType) childPromise._finallyExecuteResolve();
        }
    };

public: // ~TypedPromise()
    ~TypedPromise() {
        delete this.resolver;
        delete this.execCallbackWithParam;
        delete this.execCallbackWithoutParam;
        delete this.execCallbackWithoutPrevResult;
        delete this.simpleCallbackWithParam;
        delete this.simpleCallbackWithoutParam;
        delete this.simpleCallbackWithoutPrevResult;
        if (this.promiseChildType == NullType) delete this.parentResolver;
    };

public: // .destroy()
    void destroy()  {
        this.delay(0).finally(TypedPromise<string,string,string>::promiseCallback(TypedPromise::_destroyCallback));
    };

    static void _destroyCallback(PromiseResolver<string>* resolver) {
        BasePromise::destroy(resolver._basePromise);
    };

public: // .cancel()
    void cancel()   {
        BasePromise::destroy(&this);
    };

public: // .delay()
    TypedPromise<T2, T2, int>* delay(int ms) {
        return this.then(TypedPromise<T2, T2, int>::promiseCallback(TypedPromise::_delayCallback), ms);
    };

    static void _delayCallback(PromiseResolver<T2>* resolver, T2 prev, int ms) {
        resolver._value = prev;
        TypedTimer<PromiseResolver<T2>*>::setTimeout(TypedPromise::_timerDelayCallback, ms, resolver);
    };
    static void _timerDelayCallback(PromiseResolver<T2>* resolver) {
        resolver._resolveWithInnerValue();
    };

public: // .resolveResolver()
    template<typename TT1>
    TypedPromise<T2, T2, BasePromiseResolver*>* resolveResolver(PromiseResolver<TT1>* propResolver, TT1 propParam) {
        propResolver._value = propParam;
        BasePromiseResolver* basePromiseResolver = propResolver;
        return this.then(TypedPromise<T2, T2, BasePromiseResolver*>::promiseCallback(TypedPromise::_resolveResolverCallback), basePromiseResolver);
    };
    template<typename TT1>
    TypedPromise<T2, T2, BasePromiseResolver*>* resolveResolver(PromiseResolver<TT1>* propResolver) {
        BasePromiseResolver* basePromiseResolver = propResolver;
        return this.then(TypedPromise<T2, T2, BasePromiseResolver*>::promiseCallback(TypedPromise::_resolveResolverCallback), basePromiseResolver);
    };

    static void _resolveResolverCallback(PromiseResolver<T2>* resolver, T2 prev, BasePromiseResolver* propResolver) {
        propResolver._resolveWithInnerValue();
        resolver.resolve(prev);
    };

public: // .rejectResolver()
    template<typename TT1>
    TypedPromise<T2, T2, BasePromiseResolver*>* rejectResolver(PromiseResolver<TT1>* propResolver, string propParam) {
        propResolver._rejectValue = propParam;
        BasePromiseResolver* basePromiseResolver = propResolver;
        return this.then(TypedPromise<T2, T2, BasePromiseResolver*>::promiseCallback(TypedPromise::_rejectResolverCallback), basePromiseResolver);
    };
    template<typename TT1>
    TypedPromise<T2, T2, BasePromiseResolver*>* rejectResolver(PromiseResolver<TT1>* resolver) {
        BasePromiseResolver* basePromiseResolver = propResolver;
        return this.then(TypedPromise<T2, T2, BasePromiseResolver*>::promiseCallback(TypedPromise::_rejectResolverCallback), basePromiseResolver);
    };

    static void _rejectResolverCallback(PromiseResolver<T2>* resolver, T2 prev, BasePromiseResolver* propResolver) {
        propResolver._rejectWithInnerValue();
        resolver.resolve(prev);
    };

public: // .addCancelHandler()
    TypedPromise* addCancelHandler(SimpleCallbackWithoutParam c)                      {
        return this.addCancelHandler(TypedPromise<string, string, string>::callbackWithParam(c));
    };
    TypedPromise* addCancelHandler(SimpleCallbackWithStringParam c, string param_)    {
        return this.addCancelHandler(TypedPromise<string, string, string>::callbackWithParam(c), param_);
    };
    
    template<typename TT1>
    TypedPromise* addCancelHandler(TypedPromiseCallback<TT1>* handler) {
        BasePromiseCallback* baseHandler = handler;
        BasePromise::addObjectToArray(this.cancelHandlers, baseHandler);
        return &this;
    };
    template<typename TT1>
    TypedPromise* addCancelHandler(TypedPromiseCallback<TT1>* handler, TT1 param_) {
        handler._param = param_;
        BasePromiseCallback* baseHandler = handler;
        BasePromise::addObjectToArray(this.cancelHandlers, baseHandler);
        return &this;
    };

public: // .resolve()
    template<typename TT1>
    TypedPromise<T2, TT1, TT1>* resolve(TT1 param_) {
        return this.then(TypedPromise<T2, TT1, TT1>::promiseCallback(TypedPromise<T2, TT1, TT1>::_resolveParamCallback), param_);
    };
    
    static void _resolveParamCallback(PromiseResolver<T2>* resolver, T1 prev, T2 param) {
        resolver.resolve(param);
    };

public: // .error() 
    TypedPromise<T2, T2, string>* error(string message) {
        return this.then(TypedPromise<T2, T2, string>::promiseCallback(TypedPromise<T2, T2, string>::_rejectParamCallback), message);
    };

    static void _rejectParamCallback(PromiseResolver<T2>* resolver, T1 prev, string param) {
        resolver.reject(param);
    };

public: // .deleteObject() 
    template<typename TT1>
    TypedPromise<T2, T2, PromiseResolver<T2>*>* deleteObject(TT1* object) {
        BaseDeleteObjectContainer* baseDeleteObjectContainer = new DeleteObjectContainer<TT1>(object);
        return this
            .tapCatch(TypedPromise<string, T2, BaseDeleteObjectContainer*>::promiseCallback(TypedPromise<string, T2, BaseDeleteObjectContainer*>::_deleteObjectAndResolve), baseDeleteObjectContainer)
            .tap(TypedPromise<T2, T2, BaseDeleteObjectContainer*>::promiseCallback(TypedPromise<T2, T2, BaseDeleteObjectContainer*>::_deleteObjectAndResolve), baseDeleteObjectContainer);
    };

    static void _deleteObjectAndResolve(PromiseResolver<T2>* resolver, T1 prev, BaseDeleteObjectContainer* paramObject) {
        delete paramObject;
        resolver.resolve();
    };
};
