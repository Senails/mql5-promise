typedef void (*PromiseCallback)(ulong, string, string);
typedef void (*PromiseAllCallback)(ulong, string &[], string);

class Promise {
    class Resolver;

    static ulong idCounter;
    static Promise* allPromises[];
    static Resolver* allResolvers[];

    enum PromiseStatusTypes { Resolved, Rejected, inProgress };
    enum PromiseResolverType { PromiseAll, PromiseAny, PromiseRace };
public:
    Promise(PromiseCallback call, string paramm = ""): id(idCounter++), callback(call), param(paramm), status(inProgress) {
        this.init();
    }

    Promise* then(PromiseCallback call, string paramm = "")    { return this._then(call, paramm); }
    Promise* ccatch(PromiseCallback call, string paramm = "")  { return this._catch(call, paramm); }
    Promise* finally(PromiseCallback call, string paramm = "")  { return this._finally(call, paramm); }
    void destroy() { this._destroy(); }

    static void resolveById(ulong id, string paramm = "") {
        Promise* promise = Promise::getPromiseByID(id);
        if (promise) promise.resolve(paramm);
    }
    static void rejectById(ulong id, string paramm = "") {
        Promise* promise = Promise::getPromiseByID(id);
        if (promise) promise.reject(paramm);
    }

    static Promise* all(Promise* &promiseList[], PromiseAllCallback call, string paramm = "")   { return Resolver::resolve(new Resolver(promiseList, call, PromiseAll, paramm)); }
    static Promise* race(Promise* &promiseList[], PromiseCallback call, string paramm = "")     { return Resolver::resolve(new Resolver(promiseList, call, PromiseRace, paramm)); }
    static Promise* any(Promise* &promiseList[], PromiseCallback call, string paramm = "")      { return Resolver::resolve(new Resolver(promiseList, call, PromiseAny, paramm)); }

    ~Promise() {
        for( int i = 0; i < ArraySize(this.thenChildPromises); i++ ) delete this.thenChildPromises[i];
        for( int i = 0; i < ArraySize(this.catchChildPromises); i++ ) delete this.catchChildPromises[i];
        for( int i = 0; i < ArraySize(this.finalyChildPromises); i++ ) delete this.finalyChildPromises[i];
    }
private:
    Promise* parentPromise;
    Promise* thenChildPromises[];
    Promise* catchChildPromises[];
    Promise* finalyChildPromises[];

    ulong id;
    PromiseStatusTypes status;

    string param;
    string result;
    PromiseCallback callback;

    Promise(PromiseCallback call, Promise* prom, string paramm): id(idCounter++), callback(call), status(inProgress), parentPromise(prom), param(paramm) {
        this.init();
    };

    void init() {
        ArrayResize(this.thenChildPromises, 0, 2);
        ArrayResize(this.catchChildPromises, 0, 2);
        ArrayResize(this.finalyChildPromises, 0, 2);

        ArrayResize(Promise::allPromises, ArraySize(Promise::allPromises) + 1, 50);
        Promise::allPromises[ArraySize(Promise::allPromises) - 1] = &this;
        if (this.parentPromise == NULL) this.callback(this.id, "", this.param);
    }

    Promise* _then(PromiseCallback call, string paramm) {
        Promise* childPromis = new Promise(call, &this, paramm);
        ArrayResize(this.thenChildPromises, ArraySize(this.thenChildPromises) + 1, 2);
        this.thenChildPromises[ArraySize(this.thenChildPromises) - 1] = childPromis;

        if(this.status == Resolved) {
            childPromis.callback(childPromis.id, this.result, childPromis.param);
            return childPromis;
        };
        if(this.status == Rejected) {
            childPromis.reject(this.result);
            return childPromis;
        };
        return childPromis;
    }
    Promise* _catch(PromiseCallback call, string paramm) {
        Promise* childPromis = new Promise(call, &this, paramm);
        ArrayResize(this.catchChildPromises, ArraySize(this.catchChildPromises) + 1, 2);
        this.catchChildPromises[ArraySize(this.catchChildPromises) - 1] = childPromis;

        if(this.status == Rejected) {
            childPromis.callback(childPromis.id, this.result, childPromis.param);
            return childPromis;
        };
        if(this.status == Resolved) {
            childPromis.resolve(this.result);
            return childPromis;
        };
        return childPromis;
    }
    Promise* _finally(PromiseCallback call, string paramm) {
        Promise* childPromis = new Promise(call, &this, paramm);
        ArrayResize(this.finalyChildPromises, ArraySize(this.finalyChildPromises) + 1, 2);
        this.finalyChildPromises[ArraySize(this.finalyChildPromises) - 1] = childPromis;

        if(this.status == Resolved) {
            childPromis.callback(childPromis.id, this.result, childPromis.param);
            return childPromis;
        };
        if(this.status == Rejected) {
            childPromis.callback(childPromis.id, "", childPromis.param);
            return childPromis;
        };
        return childPromis;
    }
    void _destroy() {
        Promise* childPromis = new Promise(Promise::destroyPromiseCallback, &this, "");
        ArrayResize(this.finalyChildPromises, ArraySize(this.finalyChildPromises) + 1, 2);
        this.finalyChildPromises[ArraySize(this.finalyChildPromises) - 1] = childPromis;
        if (this.status != inProgress) childPromis.callback(childPromis.id, this.result, childPromis.param);
    }

    void resolve(string paramm = "") {
        if (this.status != inProgress) return;
        this.status = Resolved;
        this.result = paramm;

        for (int i = 0; i < ArraySize(this.finalyChildPromises); i++) {
            Promise* promise = this.finalyChildPromises[i];
            promise.callback(promise.id, this.result, promise.param);
        }
        for (int i = 0; i < ArraySize(this.thenChildPromises); i++) {
            Promise* promise = this.thenChildPromises[i];
            promise.callback(promise.id, this.result, promise.param);
        }
        for (int i = 0; i < ArraySize(this.catchChildPromises); i++) {
            this.catchChildPromises[i].resolve(this.result);
        }
    }
    void reject(string paramm = "") {
        if (this.status != inProgress) return;
        this.status = Rejected;
        this.result = paramm;

        for (int i = 0; i < ArraySize(this.finalyChildPromises); i++) {
            Promise* promise = this.finalyChildPromises[i];
            promise.callback(promise.id, "", promise.param);
        }
        for (int i = 0; i < ArraySize(this.catchChildPromises); i++) {
            Promise* promise = this.catchChildPromises[i];
            promise.callback(promise.id, this.result, promise.param);
        }
        for (int i = 0; i < ArraySize(this.thenChildPromises); i++) {
            this.thenChildPromises[i].reject(this.result);
        }
    }
    
    static Promise* getPromiseByID(ulong id) {
        int left = 0;
        int right = ArraySize(Promise::allPromises) - 1;

        while (left <= right) {
            int mid = left + (right - left) / 2;
            if (Promise::allPromises[mid].id == id) return Promise::allPromises[mid];
            if (Promise::allPromises[mid].id < id) {
                left = mid + 1;
                continue;
            }
            right = mid - 1;
        }

        return NULL;
    }
    static void destroy(Promise* promise) {
        if (promise.parentPromise) {
            Promise::destroy(promise.parentPromise);
            return;
        }
        delete promise;
        Promise::cleanupAllPromises();
    }
    static void cleanupAllPromises() {
        int validIndex = 0; 
        for (int i = 0; i < ArraySize(Promise::allPromises); i++) {
            if (CheckPointer(Promise::allPromises[i]) == POINTER_DYNAMIC) {
                Promise::allPromises[validIndex++] = Promise::allPromises[i];
            }
        }
        ArrayResize(Promise::allPromises, validIndex, 50);
    }
    static void mackPromiseCallback(ulong promiseId, string result, string param) {}
    static void destroyPromiseCallback(ulong promiseId, string result, string param) {
        Promise::destroy(Promise::getPromiseByID(promiseId));
    }

    class Resolver {
    public:
        ulong id;
        ulong resolveCount;
        ulong rejectCount;
        Promise* resultPromise;

        string param;
        PromiseResolverType type;
        Promise* promiseList[];
        PromiseAllCallback promiseAllCallback;
        PromiseCallback promiseCallback;

        Resolver(Promise* &promisList[], PromiseAllCallback call, PromiseResolverType typ, string paramm): id(idCounter++), promiseAllCallback(call), type(typ), param(paramm), resolveCount(0), rejectCount(0), resultPromise(new Promise(mackPromiseCallback)) {
            this.init(promisList);
        }
        Resolver(Promise* &promisList[], PromiseCallback call, PromiseResolverType typ, string paramm): id(idCounter++), promiseCallback(call), type(typ), param(paramm), resolveCount(0), rejectCount(0), resultPromise(new Promise(mackPromiseCallback)) {
            this.init(promisList);
        }

        void init(Promise* &promisList[]) {
            ArrayResize(Promise::allResolvers, ArraySize(Promise::allResolvers) + 1, 10);
            Promise::allResolvers[ArraySize(Promise::allResolvers) - 1] = &this;

            ArrayResize(this.promiseList, ArraySize(promisList));
            for(int i = 0; i < ArraySize(promisList); i++) this.promiseList[i] = promisList[i];
        }

        ~Resolver() {
            for(int i = 0; i < ArraySize(this.promiseList); i++) Promise::destroy(this.promiseList[i]);
        }

        static Promise* resolve(Resolver* resolver) {
            Promise* resultPromise = resolver.resultPromise;
            int arraySize = ArraySize(resolver.promiseList);
            ulong resolverId = resolver.id;

            for(int i = 0; i < arraySize; i++) {
                if (resultPromise.status != inProgress) return resultPromise;
                Promise* promise = resolver.promiseList[i].then(Resolver::promiseResolveHandler, string(resolverId));
                if (CheckPointer(promise) == POINTER_DYNAMIC) promise.ccatch(Resolver::promiseRejectHandler, string(resolverId));
            }

            return resultPromise;
        }
        static Resolver* getResolverByID(ulong id) {
            int left = 0;
            int right = ArraySize(Promise::allResolvers) - 1;

            while (left <= right) {
                int mid = left + (right - left) / 2;
                if (Promise::allResolvers[mid].id == id) return Promise::allResolvers[mid];
                if (Promise::allResolvers[mid].id < id) {
                    left = mid + 1;
                    continue;
                }
                right = mid - 1;
            }

            return NULL;
        }
        static void promiseResolveHandler(ulong promiseId, string result, string param) {
            Resolver* resolver = Resolver::getResolverByID(ulong(param));

            if (resolver.type == PromiseAny || resolver.type == PromiseRace) {
                resolver.promiseCallback(resolver.resultPromise.id, result, resolver.param);
                Resolver::destroy(resolver);
                return;
            }
            if (resolver.type == PromiseAll) {
                resolver.resolveCount++;
                if (resolver.resolveCount == ArraySize(resolver.promiseList)) {
                    string resultList[]; ArrayResize(resultList, ArraySize(resolver.promiseList));

                    for(int i = 0; i < ArraySize(resolver.promiseList); i++) {
                        resultList[i] = resolver.promiseList[i].result;
                    }

                    resolver.promiseAllCallback(resolver.resultPromise.id, resultList, resolver.param);
                    Resolver::destroy(resolver);
                    return;
                }
            }
        }
        static void promiseRejectHandler(ulong promiseId, string result, string param) {
            Resolver* resolver = Resolver::getResolverByID(ulong(param));

            if (resolver.type == PromiseAll || resolver.type == PromiseRace) {
                resolver.resultPromise.reject(result);
                Resolver::destroy(resolver);
                return;
            }
            if (resolver.type == PromiseAny) {
                resolver.rejectCount++;
                if (resolver.rejectCount == ArraySize(resolver.promiseList)) {
                    resolver.resultPromise.reject();
                    Resolver::destroy(resolver);
                    return;
                }
            }
        }
        static void destroy(Resolver* resolver) {
            delete resolver;
            Resolver::cleanupAllResolvers();
        }
        static void cleanupAllResolvers() {
            int validIndex = 0; 
            for (int i = 0; i < ArraySize(Promise::allResolvers); i++) {
                if (CheckPointer(Promise::allResolvers[i]) == POINTER_DYNAMIC) {
                    Promise::allResolvers[validIndex++] = Promise::allResolvers[i];
                }
            }
            ArrayResize(Promise::allResolvers, validIndex, 10);
        }
    };

    class PromiseInitializerAndDestructor {
    public:
        PromiseInitializerAndDestructor() {
            ArrayResize(Promise::allResolvers, 0, 10);
            ArrayResize(Promise::allPromises, 0, 50);
        }
        ~PromiseInitializerAndDestructor() {
            for (int i = ArraySize(Promise::allResolvers) - 1; i >= 0; i--) {
                if (CheckPointer(Promise::allResolvers[i]) == POINTER_DYNAMIC) delete Promise::allResolvers[i];
            }
            for (int i = 0; i < ArraySize(Promise::allPromises); i++) {
                if (CheckPointer(Promise::allPromises[i]) == POINTER_DYNAMIC) delete Promise::allPromises[i];
            }
        }
    };
};

ulong Promise::idCounter = 0;
Promise* Promise::allPromises[];
Promise::Resolver* Promise::allResolvers[];
Promise::PromiseInitializerAndDestructor promiseInitializerAndDestructor;
////////////////////////////////

// typed promise
template<typename T1, typename T2, typename T3>
class TypedCallbackWithoutPrevResult {
public:
    typedef void (*CallbackWithoutPrevResult)(TypedPromiseResolver<T2>*);
    CallbackWithoutPrevResult callback;
    TypedCallbackWithoutPrevResult(CallbackWithoutPrevResult c): callback(c) {};
};
template<typename T1, typename T2, typename T3>
class TypedCallbackWithoutParam {
public:
    typedef void (*CallbackWithoutParam)(TypedPromiseResolver<T2>*, T1);
    CallbackWithoutParam callback;
    TypedCallbackWithoutParam(CallbackWithoutParam c): callback(c) {};
};
template<typename T1, typename T2, typename T3>
class TypedCallbackWithParam {
public:
    typedef void (*CallbackWithParam)(TypedPromiseResolver<T2>*, T1, T3);
    CallbackWithParam callback;
    TypedCallbackWithParam(CallbackWithParam c): callback(c) {};
};

class BasePromise {
    static ulong idCounter;
    static int deletedPromiseCounter;
    static BasePromise* allPromises[];

    enum PromiseStatusTypes { Resolved, Rejected, inProgress, Deleted };
public:
    bool isResolved() { return this.status == Resolved; };
    bool isRejected() { return this.status == Resolved; };
    bool isInProgress() { return this.status == inProgress; };
    bool isWaitForDelete() { return this.status == Deleted; };

    void virtual _resolveHandler() {};
    void virtual _rejectHandler() {};
protected:
    ulong id;
    PromiseStatusTypes status;

    BasePromise* parentPromise;
    BasePromise* parentPromises[];
    BasePromise* thenChildPromises[];
    BasePromise* catchChildPromises[];
    BasePromise* finallyChildPromises[];

    BasePromise(): id(BasePromise::idCounter++), status(inProgress) {
        ArrayResize(this.parentPromises, 0, 2);
        ArrayResize(this.thenChildPromises, 0, 2);
        ArrayResize(this.catchChildPromises, 0, 2);
        ArrayResize(this.finallyChildPromises, 0, 2);

        BasePromise::addPromiseToArray(BasePromise::allPromises, &this);
    };

    static void addPromiseToArray(BasePromise* &array[], BasePromise* promise) {
        int currentSize = ArraySize(array);
        ArrayResize(array, currentSize + 1, MathMax(currentSize/10, 10));
        array[currentSize] = promise;
    }

    static BasePromise* getPromiseByID(ulong id) {
        int left = 0;
        int right = ArraySize(BasePromise::allPromises) - 1;

        while (left <= right) {
            int mid = left + (right - left) / 2;
            if (BasePromise::allPromises[mid].id == id) return BasePromise::allPromises[mid];
            if (BasePromise::allPromises[mid].id < id) {
                left = mid + 1;
                continue;
            }
            right = mid - 1;
        }

        return NULL;
    }

    static void destroy(BasePromise* promise) {
        promise.status = Deleted;
        BasePromise::deletedPromiseCounter++;

        for (int i = 0; i < ArraySize(promise.thenChildPromises); i++) promise.thenChildPromises[i].parentPromise = NULL;
        for (int i = 0; i < ArraySize(promise.catchChildPromises); i++) promise.catchChildPromises[i].parentPromise = NULL;
        for (int i = 0; i < ArraySize(promise.finallyChildPromises); i++) promise.finallyChildPromises[i].parentPromise = NULL;

        if (ArraySize(promise.parentPromises) > 0) {
            for (int i = 0; i < ArraySize(promise.parentPromises); i++) {
                BasePromise* parentPromises = promise.parentPromises[i];
                if (parentPromises.isResolved() || parentPromises.isRejected()) BasePromise::destroy(promise.parentPromises[i]);
            }
        }

        int allPromiseCount = ArraySize(BasePromise::allPromises);
        if (BasePromise::deletedPromiseCounter > 10 && BasePromise::deletedPromiseCounter > (allPromiseCount/20)) {
            BasePromise::cleanupAllPromises();
            BasePromise::deletedPromiseCounter = 0;
        }
    }

    static void cleanupAllPromises() {
        int validIndex = 0; 
        for (int i = 0; i < ArraySize(BasePromise::allPromises); i++) {
            if (BasePromise::allPromises[i].status == Deleted) {
                delete BasePromise::allPromises[i];
                continue;
            }
            BasePromise::allPromises[validIndex++] = BasePromise::allPromises[i];
        }
        
        ArrayResize(BasePromise::allPromises, validIndex, MathMax(validIndex/20, 50));
    }

    class PromiseInitializerAndDestructor {
    public:
        ~PromiseInitializerAndDestructor() {
            for (int i = 0; i < ArraySize(BasePromise::allPromises); i++) delete BasePromise::allPromises[i];
        }
    };
};

template<typename T>
class TypedPromiseResolver {
public:
    BasePromise* _basePromise;
    T _value;
    string _rejectValue;
    bool _alreadyResolved;

    TypedPromiseResolver(BasePromise* promise): _basePromise(promise), _alreadyResolved(false) {};

    void resolve(T resolveParam) {
        if (!this._alreadyResolved) {
            this._value = resolveParam;
            this._alreadyResolved = true;
            this._basePromise._resolveHandler();
        }
    };
    void reject(string rejectParam) {
        if (!this._alreadyResolved) {
            this._rejectValue = rejectParam;
            this._alreadyResolved = true;
            this._basePromise._rejectHandler();
        }
    };
};

class PromiseResolver: public TypedPromiseResolver<string> {
public: 
    PromiseResolver(BasePromise* p): TypedPromiseResolver<string>(p) {};
};

// T1 - prev promise return type
// T2 - promise return type
// T3 - param type
template<typename T1, typename T2, typename T3>
class TypedPromise: public BasePromise {
private: // types
    class Resolver;

    // callback for current promise
    typedef void (*CallbackWithoutPrevResult)(TypedPromiseResolver<T2>*);
    typedef void (*CallbackWithoutParam)(TypedPromiseResolver<T2>*, T1);
    typedef void (*CallbackWithParam)(TypedPromiseResolver<T2>*, T1, T3);

    // callback for then promise
    typedef void (*ThenCallbackWithoutPrevResult)(TypedPromiseResolver<T2>*);
    typedef void (*ThenCallbackWithoutParam)(TypedPromiseResolver<T2>*, T2);
    typedef void (*ThenCallbackWithParam)(TypedPromiseResolver<T2>*, T2, T3);

private: // fields
    TypedPromiseResolver<T2>* resolver;

    TypedCallbackWithParam<T1,T2,T3>* callbackWithParam;
    TypedCallbackWithoutParam<T1,T2,T3>* callbackWithoutParam;
    TypedCallbackWithoutPrevResult<T1,T2,T3>* callbackWithoutPrevResult;

    bool withoutPrevResult;
    TypedPromiseResolver<T1>* parentResolver;

    bool withoutParam;
    T3 param;

public: // constructor
    TypedPromise(CallbackWithoutPrevResult call): BasePromise(), callbackWithoutPrevResult(TypedPromise::callback(call)), withoutPrevResult(true) {
        this.init();
    };
    TypedPromise(CallbackWithoutParam call): BasePromise(), callbackWithoutParam(TypedPromise::callback(call)), withoutParam(true) {
        this.init();
    };
    TypedPromise(CallbackWithParam call, T3 paramm): BasePromise(), callbackWithParam(TypedPromise::callback(call)), param(paramm) {
        this.init();
    };
    TypedPromise(TypedCallbackWithoutPrevResult<T1,T2,T3>* call): BasePromise(), callbackWithoutPrevResult(call), withoutPrevResult(true) {
        this.init();
    };
    TypedPromise(TypedCallbackWithoutParam<T1,T2,T3>* call): BasePromise(), callbackWithoutParam(call), withoutParam(true) {
        this.init();
    };
    TypedPromise(TypedCallbackWithParam<T1,T2,T3>* call, T3 paramm): BasePromise(), callbackWithParam(call), param(paramm) {
        this.init();
    };
private: // constructor
    TypedPromise(TypedCallbackWithoutPrevResult<T1,T2,T3>* call, BasePromise* parent): BasePromise(), callbackWithoutPrevResult(call), withoutPrevResult(true) {
        this.init(parent);
    };
    TypedPromise(TypedCallbackWithoutParam<T1,T2,T3>* call, BasePromise* parent): BasePromise(), callbackWithoutParam(call), withoutParam(true) {
        this.init(parent);
    };
    TypedPromise(TypedCallbackWithParam<T1,T2,T3>* call, T3 paramm, BasePromise* parent): BasePromise(), callbackWithParam(call), param(paramm) {
        this.init(parent);
    };
public: // then
    TypedPromise<T2, T2, T3>* then(ThenCallbackWithoutPrevResult call) { return this.then(TypedPromise<T2,T2,T3>::callback(call)); };
    TypedPromise<T2, T2, T3>* then(ThenCallbackWithoutParam call) { return this.then(TypedPromise<T2,T2,T3>::callback(call)); };
    TypedPromise<T2, T2, T3>* then(ThenCallbackWithParam call, T3 paramm) { return this.then(TypedPromise<T2,T2,T3>::callback(call), paramm); };

    template<typename TT1, typename TT2, typename TT3>
    TypedPromise<TT1, TT2, TT3>* then(TypedCallbackWithoutPrevResult<TT1,TT2,TT3>* call) {
        TypedPromise<TT1, TT2, TT3>* childPromise = new TypedPromise<TT1, TT2, TT3>(call, &this);
        return childPromise;
    };
    template<typename TT1, typename TT2, typename TT3>
    TypedPromise<TT1, TT2, TT3>* then(TypedCallbackWithoutParam<TT1,TT2,TT3>* call) {
        TypedPromise<TT1, TT2, TT3>* childPromise = new TypedPromise<TT1, TT2, TT3>(call, &this);
        return childPromise;
    };
    template<typename TT1, typename TT2, typename TT3>
    TypedPromise<TT1, TT2, TT3>* then(TypedCallbackWithParam<TT1,TT2,TT3>* call, TT3 paramm)    {
        TypedPromise<TT1, TT2, TT3>* childPromise = new TypedPromise<TT1, TT2, TT3>(call, paramm, &this);
        return childPromise;
    };
public:
    void destroy() {}

    void virtual _resolveHandler() override {
        Print("Promise resolve: ", resolver._value);
    };
    void virtual _rejectHandler() override {
        Print("Promise resolve: ", resolver._rejectValue);
    };

    static TypedCallbackWithoutPrevResult<T1,T2,T3>* callback(CallbackWithoutPrevResult call) {
        return new TypedCallbackWithoutPrevResult<T1,T2,T3>(call);
    };
    static TypedCallbackWithoutParam<T1,T2,T3>* callback(CallbackWithoutParam call) {
        return new TypedCallbackWithoutParam<T1,T2,T3>(call);
    };
    static TypedCallbackWithParam<T1,T2,T3>* callback(CallbackWithParam call) {
        return new TypedCallbackWithParam<T1,T2,T3>(call);
    };

    ~TypedPromise() {
        delete this.resolver;
    };
private:

    void init(BasePromise* parent) {
        this.resolver = new TypedPromiseResolver<T2>(&this);
        this.parentPromise = parent;
        BasePromise::addPromiseToArray(this.parentPromises, parent);
    };
    void init() {
        this.resolver = new TypedPromiseResolver<T2>(&this);
        this.parentResolver = new TypedPromiseResolver<T1>(&this);
        execute();
    };

    void execute() {
        if (this.withoutPrevResult) {
            this.callbackWithoutPrevResult.callback(this.resolver);
        } else if (this.withoutParam) {
            this.callbackWithoutParam.callback(this.resolver, this.parentResolver._value);
        } else {
            this.callbackWithParam.callback(this.resolver, this.parentResolver._value, this.param);
        }
    }
};

class Promisee: public TypedPromise<string, string, string> {
    public:

    Promisee(CallbackWithoutPrevResult call): TypedPromise<string, string, string>(call) {};
    Promisee(CallbackWithoutParam call): TypedPromise<string, string, string>(call) {};
    Promisee(CallbackWithParam call, string p): TypedPromise<string, string, string>(call, p) {};

    template<typename T1, typename T2, typename T3>
    static TypedPromise<T1, T2, T3>* try(TypedCallbackWithoutPrevResult<T1, T2, T3>* call) {
        return new TypedPromise<T1, T2, T3>(call);
    };
    template<typename T1, typename T2, typename T3>
    static TypedPromise<T1, T2, T3>* try(TypedCallbackWithoutParam<T1, T2, T3>* call) {
        return new TypedPromise<T1, T2, T3>(call);
    };
    template<typename T1, typename T2, typename T3>
    static TypedPromise<T1, T2, T3>* try(TypedCallbackWithParam<T1, T2, T3>* call, T3 param) {
        return new TypedPromise<T1, T2, T3>(call, param);
    };
};

ulong BasePromise::idCounter = 0;
int BasePromise::deletedPromiseCounter = 0;
BasePromise* BasePromise::allPromises[];
BasePromise::PromiseInitializerAndDestructor basePromiseInitializerAndDestructor;
