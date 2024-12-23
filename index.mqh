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

    class PromiseIniterAndDesctructor {
    public:
        PromiseIniterAndDesctructor() {
            ArrayResize(Promise::allResolvers, 0, 10);
            ArrayResize(Promise::allPromises, 0, 50);
        }
        ~PromiseIniterAndDesctructor() {
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
Promise::PromiseIniterAndDesctructor promiseIniterAndDesctructor;
