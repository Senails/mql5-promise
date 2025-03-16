#include "index2.mqh";

void OnInit() {
    Print("start");

    Promisee::try(TypedPromise<int, int, int>::callback(callback1), 123)
        .then(callback2)
        .destroy();
};

void callback1(TypedPromiseResolver<int>* resolver, int prev, int param) {
    Print("param: " + string(param));
    resolver.resolve(1234);
};

void callback2(TypedPromiseResolver<string>* resolver, int prev) {
    Print("prev: " + string(prev));
    resolver.resolve();
};
