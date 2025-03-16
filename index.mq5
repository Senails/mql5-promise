#include "index2.mqh";

void OnInit() {
    Print("start");

    Promisee::try(callback3)
        .then(callback2)
        .destroy();
};

void callback1(TypedPromiseResolver<int>* resolver, int prev, int param) {
    Print("param: " + string(param));
    resolver.resolve(1234);
};

void callback2(TypedPromiseResolver<string>* resolver, string prev) {
    Print("prev: " + string(prev));
    resolver.resolve();
};

void callback3(TypedPromiseResolver<string>* resolver) {
    Print("prev: " + "string(prev)");
    resolver.resolve("231");
};
