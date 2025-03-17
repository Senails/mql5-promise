#ifdef mql5PromiseDev
   #include "node_modules/mql5-timer/index.mqh";
#else
   #include "../mql5-timer/index.mqh";
#endif

template<typename T>
class PromiseResolver;

template<typename T1, typename T2, typename T3>
class TypedCallbackWithoutPrevResult {
public:
    typedef void (*CallbackWithoutPrevResult)(PromiseResolver<T2>*);
    CallbackWithoutPrevResult callback;
    TypedCallbackWithoutPrevResult(CallbackWithoutPrevResult c): callback(c) {};
};
template<typename T1, typename T2, typename T3>
class TypedCallbackWithoutParam {
public:
    typedef void (*CallbackWithoutParam)(PromiseResolver<T2>*, T1);
    CallbackWithoutParam callback;
    TypedCallbackWithoutParam(CallbackWithoutParam c): callback(c) {};
};
template<typename T1, typename T2, typename T3>
class TypedCallbackWithParam {
public:
    typedef void (*CallbackWithParam)(PromiseResolver<T2>*, T1, T3);
    CallbackWithParam callback;
    TypedCallbackWithParam(CallbackWithParam c): callback(c) {};
};

class BaseCancelHandler {
public:
    BaseCancelHandler() {};
    void execute() {};
};

template<typename T>
class PromiseCancelHandler {
public:
    typedef void (*CancelHandlerWithoutParam)();
    typedef void (*CancelHandlerWithParam)(T);

    CancelHandlerWithoutParam callbackWithoutParam;
    CancelHandlerWithParam callbackWithParam;
    bool _withParam;
    T _param;

    PromiseCancelHandler(CancelHandlerWithoutParam c): BaseCancelHandler(), callbackWithoutParam(c), _withParam(false) {};
    PromiseCancelHandler(CancelHandlerWithParam c): BaseCancelHandler(), callbackWithParam(c), _withParam(true) {};

    void execute() {
        if (this._withParam) {
            callbackWithParam(_param);
        } else {
            callbackWithoutParam();
        }
    };
};

class BasePromise {
protected: // types
    static ulong idCounter;
    static int deletedPromiseCounter;
    static BasePromise* allPromises[];

    enum PromiseStatusTypes { ResolvedState, RejectedState, inProgressState, DeletedState };
    enum PromiseChildType { ThenType, CatchType, FinallyType, NullType };

    typedef void (*CancelHandlerWithoutParam)();
    typedef void (*CancelHandlerWithStringParam)(string);

protected: // fields
    ulong id;
    PromiseStatusTypes promiseStatus;
    PromiseChildType promiseChildType;

    BasePromise* parentPromise;
    BasePromise* parentPromises[];
    BasePromise* childPromises[];
    BaseCancelHandler* cancelHandlers[];

protected: // constructor
    BasePromise(): id(idCounter++), promiseStatus(inProgressState), promiseChildType(NullType) {
        ArrayResize(this.parentPromises, 0, 2);
        ArrayResize(this.childPromises, 0, 2);
        ArrayResize(this.cancelHandlers, 0, 2);
        
        BasePromise::addObjectToArray(BasePromise::allPromises, &this);
    };
    BasePromise(BasePromise* parent, PromiseChildType childType): id(idCounter++), promiseStatus(inProgressState), parentPromise(parent), promiseChildType(childType) {
        ArrayResize(this.parentPromises, 0, 2);
        ArrayResize(this.childPromises, 0, 2);
        ArrayResize(this.cancelHandlers, 0, 2);

        BasePromise::addObjectToArray(this.parentPromises, parent);
        BasePromise::addObjectToArray(parent.childPromises, &this);
        BasePromise::addObjectToArray(BasePromise::allPromises, &this);
    };

public: // methods
    void virtual _resolveHandler() {};
    void virtual _rejectHandler() {};

    void virtual _thenExecuteResolve() {};
    void virtual _thenExecuteReject() {};
    void virtual _thenExecuteRejectWaitForDelete() {};

    void virtual _catchExecuteResolve() {};
    void virtual _catchExecuteReject() {};
    void virtual _catchExecuteRejectWaitForDelete() {};

    void virtual _finallyExecuteResolve() {};

protected: // utils
    template<typename T>
    static void addObjectToArray(T* &array[], T* promise) {
        int currentSize = ArraySize(array);
        ArrayResize(array, currentSize + 1, MathMax(currentSize/10, 10));
        array[currentSize] = promise;
    };
    template<typename T>
    static void removeObjectFromArray(T* &array[], T* promise) {
        int currentSize = ArraySize(array);
        for (int i = 0; i < currentSize; i++) {
            if (array[i] == promise) {
                for (int j = i; j < currentSize - 1; j++) {
                    array[j] = array[j + 1];
                }
                ArrayResize(array, currentSize - 1, MathMax(currentSize/10, 10));
                return;
            }
        }
    };

    static void destroy(BasePromise* promise) {
        for (int i = 0; i < ArraySize(promise.parentPromises); i++) {
            BasePromise* parentPromise = promise.parentPromises[i];
            BasePromise::removeObjectFromArray(parentPromise.childPromises, promise);
            if (ArraySize(parentPromise.childPromises) == 0) BasePromise::destroy(parentPromise);
        }

        promise.promiseStatus = DeletedState;
        BasePromise::deletedPromiseCounter++;
        BasePromise::cleanupAllPromises();
    };
    static void cleanupAllPromises() {
        int allPromiseCount = ArraySize(BasePromise::allPromises);

        if (BasePromise::deletedPromiseCounter > 10 && BasePromise::deletedPromiseCounter > (allPromiseCount/20)) {
            int validIndex = 0; 

            for (int i = 0; i < ArraySize(BasePromise::allPromises); i++) {
                if (BasePromise::allPromises[i].promiseStatus == DeletedState) {
                    delete BasePromise::allPromises[i];
                    continue;
                }
                BasePromise::allPromises[validIndex++] = BasePromise::allPromises[i];
            }
            
            ArrayResize(BasePromise::allPromises, validIndex, MathMax(validIndex/20, 50));
            BasePromise::deletedPromiseCounter = 0;
        }
    };

public: // initializer and destructor
    class PromiseInitializerAndDestructor {
    public:
        ~PromiseInitializerAndDestructor() { for (int i = 0; i < ArraySize(BasePromise::allPromises); i++) delete BasePromise::allPromises[i]; }
    };
};

ulong BasePromise::idCounter = 0;
int BasePromise::deletedPromiseCounter = 0;
BasePromise* BasePromise::allPromises[];
BasePromise::PromiseInitializerAndDestructor basePromiseInitializerAndDestructor;

class BasePromiseResolver {
public:
    BasePromise* _basePromise;
    string _rejectValue;
    bool _isRejected;
    bool _alreadyResolved;

    BasePromiseResolver(BasePromise* promise): _basePromise(promise), _alreadyResolved(false), _isRejected(false) {};

    void virtual _resolveWithInnerValue() {};
    void virtual _rejectWithInnerValue() { this.reject(this._rejectValue); };

    void reject(string rejectParam) {
        if (!this._alreadyResolved) {
            this._rejectValue = rejectParam;
            this._alreadyResolved = true;
            this._isRejected = true;
            this._basePromise._rejectHandler();
        }
    };
    void reject() {
        if (!this._alreadyResolved) {
            this._rejectValue = "";
            this._alreadyResolved = true;
            this._isRejected = true;
            this._basePromise._rejectHandler();
        }
    };
};

template<typename T>
class PromiseResolver: public BasePromiseResolver{
public:
    T _value;

    PromiseResolver(BasePromise* promise): BasePromiseResolver(promise) {};

    void virtual _resolveWithInnerValue() override { this.resolve(this._value); };

    void resolve(T resolveParam) {
        if (!this._alreadyResolved) {
            this._value = resolveParam;
            this._alreadyResolved = true;
            this._basePromise._resolveHandler();
        }
    };
    void resolve() {
        if (!this._alreadyResolved) {
            this._alreadyResolved = true;
            this._basePromise._resolveHandler();
        }
    };
};

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
    
public: // create callback
    static TypedCallbackWithoutPrevResult<T1,T2,T3>* callback(CallbackWithoutPrevResult call)   { return new TypedCallbackWithoutPrevResult<T1,T2,T3>(call); };
    static TypedCallbackWithoutParam<T1,T2,T3>* callback(CallbackWithoutParam call)             { return new TypedCallbackWithoutParam<T1,T2,T3>(call); };
    static TypedCallbackWithParam<T1,T2,T3>* callback(CallbackWithParam call)                   { return new TypedCallbackWithParam<T1,T2,T3>(call); };

private: // fields
    PromiseResolver<T2>* resolver;
    PromiseResolver<T1>* parentResolver;
    BasePromiseResolver* baseParentResolver;
    PromiseResolver<T2>* parentResolverWithTheSameType;

    TypedCallbackWithParam<T1, T2, T3>* callbackWithParam;
    TypedCallbackWithoutParam<T1, T2, T3>* callbackWithoutParam;
    TypedCallbackWithoutPrevResult<T1, T2, T3>* callbackWithoutPrevResult;

    TypedCallbackWithParam<string, T2, T3>* simpleCallbackWithParam;
    TypedCallbackWithoutParam<string, T2, T3>* simpleCallbackWithoutParam;
    TypedCallbackWithoutPrevResult<string, T2, T3>* simpleCallbackWithoutPrevResult;

    bool withoutPrevResult;
    bool withoutParam;
    T3 param;

public: // public constructor
    TypedPromise(CallbackWithoutPrevResult call): BasePromise(), callbackWithoutPrevResult(TypedPromise::callback(call)), withoutParam(true), withoutPrevResult(true)                           { this.init(); };
    TypedPromise(CallbackWithoutParam call): BasePromise(), callbackWithoutParam(TypedPromise::callback(call)), withoutParam(true), withoutPrevResult(false)                                    { this.init(); };
    TypedPromise(CallbackWithParam call, T3 param_): BasePromise(), callbackWithParam(TypedPromise::callback(call)), param(param_), withoutParam(false), withoutPrevResult(false)               { this.init(); };

    TypedPromise(TypedCallbackWithoutPrevResult<T1, T2, T3>* call): BasePromise(), callbackWithoutPrevResult(call), withoutParam(true), withoutPrevResult(true)                                 { this.init(); };
    TypedPromise(TypedCallbackWithoutParam<T1, T2, T3>* call): BasePromise(), callbackWithoutParam(call), withoutParam(true), withoutPrevResult(false)                                          { this.init(); };
    TypedPromise(TypedCallbackWithParam<T1, T2, T3>* call, T3 param_): BasePromise(), callbackWithParam(call), param(param_), withoutParam(false), withoutPrevResult(false)                     { this.init(); };

public: // static method constructor
    static TypedPromise<T1, T2, T3>* _createThenChildPromise(TypedCallbackWithoutPrevResult<T1, T2, T3>* call, PromiseResolver<T1>* pResolver)             { return new TypedPromise<T1, T2, T3>(call, pResolver); };
    static TypedPromise<T1, T2, T3>* _createThenChildPromise(TypedCallbackWithoutParam<T1, T2, T3>* call, PromiseResolver<T1>* pResolver)                  { return new TypedPromise<T1, T2, T3>(call, pResolver); };
    static TypedPromise<T1, T2, T3>* _createThenChildPromise(TypedCallbackWithParam<T1, T2, T3>* call, T3 param_, PromiseResolver<T1>* pResolver)          { return new TypedPromise<T1, T2, T3>(call, param_, pResolver); };

    static TypedPromise<T1, T2, T3>* _createCatchChildPromise(TypedCallbackWithoutPrevResult<string, T2, T3>* call, PromiseResolver<T2>* pResolver)        { return new TypedPromise<T1, T2, T3>(call, pResolver, true); };
    static TypedPromise<T1, T2, T3>* _createCatchChildPromise(TypedCallbackWithoutParam<string, T2, T3>* call, PromiseResolver<T2>* pResolver)             { return new TypedPromise<T1, T2, T3>(call, pResolver, true); };
    static TypedPromise<T1, T2, T3>* _createCatchChildPromise(TypedCallbackWithParam<string, T2, T3>* call, T3 param_, PromiseResolver<T2>* pResolver)     { return new TypedPromise<T1, T2, T3>(call, param_, pResolver, true); };

    static TypedPromise<T1, T2, T3>* _createFinallyChildPromise(TypedCallbackWithoutPrevResult<string, T2, T3>* call, BasePromiseResolver* pResolver)      { return new TypedPromise<T1, T2, T3>(call, pResolver, true, true); };
    static TypedPromise<T1, T2, T3>* _createFinallyChildPromise(TypedCallbackWithoutParam<string, T2, T3>* call, BasePromiseResolver* pResolver)           { return new TypedPromise<T1, T2, T3>(call, pResolver, true, true); };
    static TypedPromise<T1, T2, T3>* _createFinallyChildPromise(TypedCallbackWithParam<string, T2, T3>* call, T3 param_, BasePromiseResolver* pResolver)   { return new TypedPromise<T1, T2, T3>(call, param_, pResolver, true, true); };

private: // private constructor
    TypedPromise(TypedCallbackWithoutPrevResult<T1, T2, T3>* call, PromiseResolver<T1>* pResolver): BasePromise(pResolver._basePromise, ThenType), callbackWithoutPrevResult(call), withoutParam(true), withoutPrevResult(true) , parentResolver(pResolver)                                                { this.init(); };
    TypedPromise(TypedCallbackWithoutParam<T1, T2, T3>* call, PromiseResolver<T1>* pResolver): BasePromise(pResolver._basePromise, ThenType), callbackWithoutParam(call), withoutParam(true), withoutPrevResult(false), parentResolver(pResolver)                                                          { this.init(); };
    TypedPromise(TypedCallbackWithParam<T1, T2, T3>* call, T3 param_, PromiseResolver<T1>* pResolver): BasePromise(pResolver._basePromise, ThenType), callbackWithParam(call), param(param_), withoutParam(false), withoutPrevResult(false), parentResolver(pResolver)                                     { this.init(); };

    TypedPromise(TypedCallbackWithoutPrevResult<string, T2, T3>* call, PromiseResolver<T2>* pResolver, bool _): BasePromise(pResolver._basePromise, CatchType), simpleCallbackWithoutPrevResult(call), withoutParam(true), withoutPrevResult(true), parentResolverWithTheSameType(pResolver)               { this.init(); };
    TypedPromise(TypedCallbackWithoutParam<string, T2, T3>* call, PromiseResolver<T2>* pResolver, bool _): BasePromise(pResolver._basePromise, CatchType), simpleCallbackWithoutParam(call), withoutParam(true), withoutPrevResult(false), parentResolverWithTheSameType(pResolver)                        { this.init(); };
    TypedPromise(TypedCallbackWithParam<string, T2, T3>* call, T3 param_, PromiseResolver<T2>* pResolver, bool _): BasePromise(pResolver._basePromise, CatchType), simpleCallbackWithParam(call), param(param_), withoutParam(false), withoutPrevResult(false), parentResolverWithTheSameType(pResolver)   { this.init(); };

    TypedPromise(TypedCallbackWithoutPrevResult<string, T2, T3>* call, BasePromiseResolver* pResolver, bool _, bool __): BasePromise(pResolver._basePromise, FinallyType), simpleCallbackWithoutPrevResult(call), withoutParam(true), withoutPrevResult(true), baseParentResolver(pResolver)               { this.init(); };
    TypedPromise(TypedCallbackWithoutParam<string, T2, T3>* call, BasePromiseResolver* pResolver, bool _, bool __): BasePromise(pResolver._basePromise, FinallyType), simpleCallbackWithoutParam(call), withoutParam(true), withoutPrevResult(false), baseParentResolver(pResolver)                        { this.init(); };
    TypedPromise(TypedCallbackWithParam<string, T2, T3>* call, T3 param_, BasePromiseResolver* pResolver, bool _, bool __): BasePromise(pResolver._basePromise, FinallyType), simpleCallbackWithParam(call), param(param_), withoutParam(false), withoutPrevResult(false), baseParentResolver(pResolver)   { this.init(); };

public: // then method
    TypedPromise<T2, string, string>* then(ThenCallbackWithoutPrevResult call)                                              { return this.then(TypedPromise<T2,string,string>::callback(call)); };
    TypedPromise<T2, string, string>* then(ThenCallbackWithoutParam call)                                                   { return this.then(TypedPromise<T2,string,string>::callback(call)); };
    TypedPromise<T2, string, string>* then(ThenCallbackWithParam call, string param_)                                       { return this.then(TypedPromise<T2,string,string>::callback(call), param_); };

    template<typename TT2, typename TT3>
    TypedPromise<T2, TT2, TT3>* then(TypedCallbackWithoutPrevResult<T2, TT2, TT3>* call)                                    { return this._then(TypedPromise<T2, TT2, TT3>::_createThenChildPromise(call, this.resolver)); };
    template<typename TT2, typename TT3>
    TypedPromise<T2, TT2, TT3>* then(TypedCallbackWithoutParam<T2, TT2, TT3>* call)                                         { return this._then(TypedPromise<T2, TT2, TT3>::_createThenChildPromise(call, this.resolver)); };
    template<typename TT2, typename TT3>
    TypedPromise<T2, TT2, TT3>* then(TypedCallbackWithParam<T2, TT2, TT3>* call, TT3 param_)                                { return this._then(TypedPromise<T2, TT2, TT3>::_createThenChildPromise(call, param_, this.resolver)); };
    
public: // tap method
    TypedPromise<string, T2, PromiseResolver<T2>*>* tap(ThenCallbackWithoutPrevResult call)                                 { return this.tap(TypedPromise<T2, string, string>::callback(call)); };
    TypedPromise<string, T2, PromiseResolver<T2>*>* tap(ThenCallbackWithoutParam call)                                      { return this.tap(TypedPromise<T2, string, string>::callback(call)); };
    TypedPromise<string, T2, PromiseResolver<T2>*>* tap(ThenCallbackWithParam call, string param_)                          { return this.tap(TypedPromise<T2, string, string>::callback(call), param_); };

    template<typename TT2, typename TT3>
    TypedPromise<TT2, T2, PromiseResolver<T2>*>* tap(TypedCallbackWithoutPrevResult<T2, TT2, TT3>* call)                    { return this.then(call).then(TypedPromise<TT2, T2, PromiseResolver<T2>*>::callback(TypedPromise<TT2, T2, PromiseResolver<T2>*>::_resolveResolverValue), this.resolver); };
    template<typename TT2, typename TT3>
    TypedPromise<TT2, T2, PromiseResolver<T2>*>* tap(TypedCallbackWithoutParam<T2, TT2, TT3>* call)                         { return this.then(call).then(TypedPromise<TT2, T2, PromiseResolver<T2>*>::callback(TypedPromise<TT2, T2, PromiseResolver<T2>*>::_resolveResolverValue), this.resolver); };
    template<typename TT2, typename TT3>
    TypedPromise<TT2, T2, PromiseResolver<T2>*>* tap(TypedCallbackWithParam<T2, TT2, TT3>* call, TT3 param_)                { return this.then(call, param_).then(TypedPromise<TT2, T2, PromiseResolver<T2>*>::callback(TypedPromise<TT2, T2, PromiseResolver<T2>*>::_resolveResolverValue), this.resolver); };

public: // catch method
    TypedPromise<string, T2, string>* catch(CatchCallbackWithoutPrevResult call)                                            { return this.catch(TypedPromise<string, T2, string>::callback(call)); };
    TypedPromise<string, T2, string>* catch(CatchCallbackWithoutParam call)                                                 { return this.catch(TypedPromise<string, T2, string>::callback(call)); };
    TypedPromise<string, T2, string>* catch(CatchCallbackWithParam call, string param_)                                     { return this.catch(TypedPromise<string, T2, string>::callback(call), param_); };

    template<typename TT3>
    TypedPromise<string, T2, TT3>* catch(TypedCallbackWithoutPrevResult<string, T2, TT3>* call)                             { return this._catch(TypedPromise<string, T2, TT3>::_createCatchChildPromise(call, this.resolver)); };
    template<typename TT3>
    TypedPromise<string, T2, TT3>* catch(TypedCallbackWithoutParam<string, T2, TT3>* call)                                  { return this._catch(TypedPromise<string, T2, TT3>::_createCatchChildPromise(call, this.resolver)); };
    template<typename TT3>
    TypedPromise<string, T2, TT3>* catch(TypedCallbackWithParam<string, T2, TT3>* call, TT3 param_)                         { return this._catch(TypedPromise<string, T2, TT3>::_createCatchChildPromise(call, param_, this.resolver)); };

public: // tapCatch method
    TypedPromise<string, T2, PromiseResolver<T2>*>* tapCatch(CatchCallbackWithoutPrevResult call)                           { return this.tapCatch(TypedPromise<string, T2, string>::callback(call)); };
    TypedPromise<string, T2, PromiseResolver<T2>*>* tapCatch(CatchCallbackWithoutParam call)                                { return this.tapCatch(TypedPromise<string, T2, string>::callback(call)); };
    TypedPromise<string, T2, PromiseResolver<T2>*>* tapCatch(CatchCallbackWithParam call, string param_)                    { return this.tapCatch(TypedPromise<string, T2, string>::callback(call), param_); };

    template<typename TT3>
    TypedPromise<string, T2, PromiseResolver<T2>*>* tapCatch(TypedCallbackWithoutPrevResult<string, T2, TT3>* call)         { return this.catch(call).finally(TypedPromise<string, T2, PromiseResolver<T2>*>::callback(TypedPromise<T1, T2, T3>::_rejectResolverValueIfNeeded), this.resolver); };
    template<typename TT3>
    TypedPromise<string, T2, PromiseResolver<T2>*>* tapCatch(TypedCallbackWithoutParam<string, T2, TT3>* call)              { return this.catch(call).finally(TypedPromise<string, T2, PromiseResolver<T2>*>::callback(TypedPromise<T1, T2, T3>::_rejectResolverValueIfNeeded), this.resolver); };
    template<typename TT3>
    TypedPromise<string, T2, PromiseResolver<T2>*>* tapCatch(TypedCallbackWithParam<string, T2, TT3>* call, TT3 param_)     { return this.catch(call, param_).finally(TypedPromise<string, T2, PromiseResolver<T2>*>::callback(TypedPromise<T1, T2, T3>::_rejectResolverValueIfNeeded), this.resolver); };

public: // finally method
    TypedPromise<string, string, string>* finally(FinallyCallbackWithoutPrevResult call)                                    { return this.finally(TypedPromise<string,string,string>::callback(call)); };
    TypedPromise<string, string, string>* finally(FinallyCallbackWithoutParam call)                                         { return this.finally(TypedPromise<string,string,string>::callback(call)); };
    TypedPromise<string, string, string>* finally(FinallyCallbackWithParam call, string param_)                             { return this.finally(TypedPromise<string,string,string>::callback(call), param_); };

    template<typename TT2, typename TT3>
    TypedPromise<string, TT2, TT3>* finally(TypedCallbackWithoutPrevResult<string, TT2, TT3>* call)                         { return this._finally(TypedPromise<string, TT2, TT3>::_createFinallyChildPromise(call, this.resolver)); };
    template<typename TT2, typename TT3>
    TypedPromise<string, TT2, TT3>* finally(TypedCallbackWithoutParam<string, TT2, TT3>* call)                              { return this._finally(TypedPromise<string, TT2, TT3>::_createFinallyChildPromise(call, this.resolver)); };
    template<typename TT2, typename TT3>
    TypedPromise<string, TT2, TT3>* finally(TypedCallbackWithParam<string, TT2, TT3>* call, TT3 param_)                     { return this._finally(TypedPromise<string, TT2, TT3>::_createFinallyChildPromise(call, param_, this.resolver)); };

private: // then, catch, finally, init handlers
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

    void init() {
        this.resolver = new PromiseResolver<T2>(&this);
        if (this.promiseChildType != NullType) return;

        this.parentResolver = new PromiseResolver<T1>(&this);
        this._thenExecuteResolve();
    };

public: // then, catch, finally executors
    void virtual _thenExecuteResolve() override {
        bool withoutPrevResult_ = this.withoutPrevResult;
        bool withoutParam_ = this.withoutParam;

        if (withoutPrevResult_) {
            this.callbackWithoutPrevResult.callback(this.resolver);
        } else if (withoutParam_) {
            this.callbackWithoutParam.callback(this.resolver, this.parentResolver._value);
        } else {
            this.callbackWithParam.callback(this.resolver, this.parentResolver._value, this.param);
        }
    };
    void virtual _thenExecuteReject() override {
        this.resolver.reject(this.parentResolver._rejectValue);
    };
    void virtual _thenExecuteRejectWaitForDelete() override {
        this.resolver.reject("The object is awaiting deletion");
    };

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

public: // resolve and reject handlers
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

public: // destroy and cancel
    void destroy()  { this.delay(0).finally(TypedPromise<string,string,string>::callback(TypedPromise::destroyCallback)); };
    void cancel()   { BasePromise::destroy(&this); };

    ~TypedPromise() {
        delete this.resolver;
        delete this.callbackWithParam;
        delete this.callbackWithoutParam;
        delete this.callbackWithoutPrevResult;
        delete this.simpleCallbackWithParam;
        delete this.simpleCallbackWithoutParam;
        delete this.simpleCallbackWithoutPrevResult;
        if (this.promiseChildType == NullType) delete this.parentResolver;
    };

public: // utils
    TypedPromise<T2, T2, int>* delay(int ms) { return this.then(TypedPromise<T2, T2, int>::callback(TypedPromise::delayCallback), ms); };

    template<typename TT1>
    TypedPromise<T2, T2, BasePromiseResolver*>* resolveResolver(PromiseResolver<TT1>* propResolver, TT1 propParam) {
        propResolver._value = propParam;
        BasePromiseResolver* basePromiseResolver = propResolver;
        return this.then(TypedPromise<T2, T2, BasePromiseResolver*>::callback(TypedPromise<T1, T2, T3>::resolveResolverCallback), basePromiseResolver);
    };
    template<typename TT1>
    TypedPromise<T2, T2, BasePromiseResolver*>* resolveResolver(PromiseResolver<TT1>* propResolver) {
        BasePromiseResolver* basePromiseResolver = propResolver;
        return this.then(TypedPromise<T2, T2, BasePromiseResolver*>::callback(TypedPromise::resolveResolverCallback), basePromiseResolver);
    };

    template<typename TT1>
    TypedPromise<T2, T2, BasePromiseResolver*>* rejectResolver(PromiseResolver<TT1>* propResolver, string propParam) {
        propResolver._rejectValue = propParam;
        BasePromiseResolver* basePromiseResolver = propResolver;
        return this.then(TypedPromise<T2, T2, BasePromiseResolver*>::callback(TypedPromise::rejectResolverCallback), basePromiseResolver);
    };
    template<typename TT1>
    TypedPromise<T2, T2, BasePromiseResolver*>* rejectResolver(PromiseResolver<TT1>* resolver) {
        BasePromiseResolver* basePromiseResolver = propResolver;
        return this.then(TypedPromise<T2, T2, BasePromiseResolver*>::callback(TypedPromise::rejectResolverCallback), basePromiseResolver);
    };

    void addCancelHandler(CancelHandlerWithoutParam c) {

    }
    void addCancelHandler(CancelHandlerWithStringParam c, string param) {
        
    }
    template<typename TT1>
    void addCancelHandler() {
        
    }

    // template<typename TT1>
    // TypedPromise<T2, TT1, TT1>* resolveParam(TT1 param) {
    //     return this.then()
    // }

    // TypedPromise<T2, string, string>* rejectMessage(string message) {
    //     return this.then()
    // }

protected: // callbacks
    static void destroyCallback(PromiseResolver<string>* resolver) { BasePromise::destroy(resolver._basePromise); };

    static void delayCallback(PromiseResolver<T2>* resolver, T2 prev, int ms) {
        resolver._value = prev;
        TypedTimer<PromiseResolver<T2>*>::setTimeout(TypedPromise::timerDelayCallback, ms, resolver);
    };
    static void timerDelayCallback(PromiseResolver<T2>* resolver) {
        resolver._resolveWithInnerValue();
    };

    static void resolveResolverCallback(PromiseResolver<T2>* resolver, T2 prev, BasePromiseResolver* propResolver) {
        propResolver._resolveWithInnerValue();
        resolver.resolve(prev);
    };
    static void rejectResolverCallback(PromiseResolver<T2>* resolver, T2 prev, BasePromiseResolver* propResolver) {
        propResolver._rejectWithInnerValue();
        resolver.resolve(prev);
    };
public: // callbacks
    static void _resolveParamCallback(PromiseResolver<T2>* resolver, string prev, T2 param) { resolver.resolve(param); };
    static void _rejectParamCallback(PromiseResolver<string>* resolver, string prev, string param) { resolver.reject(param); };
    static void _resolveResolverValue(PromiseResolver<T2>* resolver, T1 prev, PromiseResolver<T2>* propResolver) { resolver.resolve(propResolver._value); };
    static void _rejectResolverValueIfNeeded(PromiseResolver<T2>* resolver, string prev, PromiseResolver<T2>* propResolver) {
        if (propResolver._isRejected) {
            resolver.reject(propResolver._rejectValue);
        } else {
            resolver.resolve(propResolver._value);
        }
    };
};

class Promise: public TypedPromise<string, string, string> {
    public:

    Promise(CallbackWithoutPrevResult call): TypedPromise<string, string, string>(call) {};
    Promise(CallbackWithoutParam call): TypedPromise<string, string, string>(call) {};
    Promise(CallbackWithParam call, string p): TypedPromise<string, string, string>(call, p) {};

    static TypedPromise<string, string, string>* try(CallbackWithoutPrevResult call)            { return new Promise(call); };
    static TypedPromise<string, string, string>* try(CallbackWithoutParam call)                 { return new Promise(call); };
    static TypedPromise<string, string, string>* try(CallbackWithParam call, string p)          { return new Promise(call, p); };

    template<typename T2>
    static TypedPromise<string, T2, T2>* resolve(T2 param) { return new TypedPromise<string, T2, T2>(TypedPromise<string, T2, T2>::_resolveParamCallback, param); };
    static TypedPromise<string, string, string>* resolve() { return new Promise(Promise::_resolveParamCallback, ""); };

    static TypedPromise<string, string, string>* reject(string message = "") { return new Promise(Promise::_rejectParamCallback, ""); };

    template<typename T1, typename T2, typename T3>
    static TypedPromise<T1, T2, T3>* try(TypedCallbackWithoutPrevResult<T1, T2, T3>* call)      { return new TypedPromise<T1, T2, T3>(call); };
    template<typename T1, typename T2, typename T3>
    static TypedPromise<T1, T2, T3>* try(TypedCallbackWithoutParam<T1, T2, T3>* call)           { return new TypedPromise<T1, T2, T3>(call); };
    template<typename T1, typename T2, typename T3>
    static TypedPromise<T1, T2, T3>* try(TypedCallbackWithParam<T1, T2, T3>* call, T3 param)    { return new TypedPromise<T1, T2, T3>(call, param); };
};
