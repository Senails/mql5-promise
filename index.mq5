#define mql5PromiseDev "";
#include "index2.mqh";

void OnInit() {
    Print("start");

    Promise::try(TypedPromise<int, int, int>::callback(callback1))
        .tap(tapCallback)
        .delay(3000)
        .then(callback2)
        .catch(catchCallback)
        .tapCatch(catchCallback)
        .destroy();
};

void callback1(PromiseResolver<int>* resolver) {
    Print("prev: " + "string(prev)");

    Promise::resolve()
        .resolveResolver(resolver, 321)
        .destroy();
};

void callback2(PromiseResolver<string>* resolver, int prev) {
    Print("prev: " + string(prev));
    resolver.resolve();
};

void tapCallback(PromiseResolver<string>* resolver) {
    Print("tapCallback ");
    resolver.resolve();
}

void catchCallback(PromiseResolver<string>* resolver) {
    Print("catchCallback ");
    resolver.resolve("catchCallback");
}
