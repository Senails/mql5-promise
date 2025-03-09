#include "index2.mqh";

void OnInit() {
    Print("start");
    BasePromise* tt = new TypedPromise<string, string, string>(callback);
}

void callback(TypedPromiseResolver<string>* resolver) {
    resolver.resolve("1234");
    resolver.reject("4321");
}
