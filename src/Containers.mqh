class BasePromiseDeleteObjectContainer {};

template<typename T>
class PromiseDeleteObjectContainer: public BasePromiseDeleteObjectContainer {
public: // fields
    T* obj;

public: // PromiseDeleteObjectContainer()
    PromiseDeleteObjectContainer(T* o): BasePromiseDeleteObjectContainer(), obj(o) {};

public: // ~PromiseDeleteObjectContainer()
    ~PromiseDeleteObjectContainer() { delete obj; };
};

template<typename T>
class PromiseErrorAndValueContainer {
public: // fields
    T value;
    string error;
public: // PromiseErrorAndValueContainer()
    PromiseErrorAndValueContainer(string e, T v): error(e), value(v) {};
};
