class BaseDeleteObjectContainer {};

template<typename T>
class DeleteObjectContainer: public BaseDeleteObjectContainer {
public: // fields
    T* obj;

public: // DeleteObjectContainer()
    DeleteObjectContainer(T* o): BaseDeleteObjectContainer(), obj(o) {};

public: // ~DeleteObjectContainer()
    ~DeleteObjectContainer() { delete obj; };
};

template<typename T>
class PromiseErrorAndValueContainer {
public: // fields
    T value;
    string error;
public: // PromiseErrorAndValueContainer()
    PromiseErrorAndValueContainer(string e, T v): error(e), value(v) {};
};
