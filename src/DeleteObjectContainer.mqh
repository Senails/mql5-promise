class BaseDeleteObjectContainer {};
template<typename T>

class DeleteObjectContainer: public BaseDeleteObjectContainer {
public:
    T* obj;
    DeleteObjectContainer(T* o): BaseDeleteObjectContainer(), obj(o) {};
    ~DeleteObjectContainer() { delete obj; };
};
