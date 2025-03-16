#define mql5PromiseDev "";
#include "index2.mqh";

void OnInit() {
    Print("start");

    Promisee::try(TypedPromise<int, int, int>::callback(callback1))
        .delay(3000)
        .then(callback2)
        .destroy();
};

void callback1(PromiseResolver<int>* resolver) {
    Print("prev: " + "string(prev)");

    Promisee::resolve()
        .resolveResolver(resolver)
        .destroy();
};

void callback3(PromiseResolver<int>* resolver) { resolver.resolve(); };

void callback2(PromiseResolver<string>* resolver, int prev) {
    Print("prev: " + string(prev));
    resolver.resolve();
};
