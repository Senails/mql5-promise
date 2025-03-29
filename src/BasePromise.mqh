class BasePromise {
protected: // types
    static ulong idCounter;
    static int deletedPromiseCounter;
    static BasePromise* allPromises[];

    enum PromiseStatusTypes { ResolvedState, RejectedState, inProgressState, DeletedState };
    enum PromiseChildType { ThenType, CatchType, FinallyType, NullType };

protected: // fields
    ulong id;
    PromiseStatusTypes promiseStatus;
    PromiseChildType promiseChildType;

    BasePromise* parentPromise;
    BasePromise* parentPromises[];
    BasePromise* childPromises[];
    BasePromiseCallback* cancelHandlers[];

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
