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
