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
