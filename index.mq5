#include "index2.mqh";

void OnInit() {
    Print("start");

    Promisee::try(TypedPromise<int, int, int>::callback(callback1), 123);
    // new TypedPromise<int, int, int>(TypedPromise<int, int, int>::callback(callback1), 123);
};

void callback1(TypedPromiseResolver<int>* resolver, int prev, int param) {
    resolver.resolve(1234);
    resolver.reject("4321");
};
