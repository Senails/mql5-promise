class BasePromiseResolver {
public: // fields
    BasePromise* _basePromise;
    string _rejectValue;
    bool _isRejected;
    bool _alreadyResolved;

public: // BasePromiseResolver()
    BasePromiseResolver(BasePromise* promise): _basePromise(promise), _alreadyResolved(false), _isRejected(false) {};

public: // ._resolveWithInnerValue()
    void virtual _resolveWithInnerValue() {};
public: // ._rejectWithInnerValue()
    void virtual _rejectWithInnerValue() {
        this.reject(this._rejectValue);
    };

public: // .reject()
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
public: // fields
    T _value;

public: // PromiseResolver()
    PromiseResolver(BasePromise* promise): BasePromiseResolver(promise) {};

public: // ._resolveWithInnerValue()
    void virtual _resolveWithInnerValue() override {
        this.resolve(this._value);
    };

public: // .resolve()
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
