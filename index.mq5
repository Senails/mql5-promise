#define mql5PromiseDev "";
#include "src/index.mqh";

void OnInit() {
    Print("start");

    BaseDeleteObjectContainer* obj = new BaseDeleteObjectContainer();

    Promise::try(TypedPromise<int, int, int>::promiseCallback(callback1))
        .tap(tapCallback)
        .addCancelHandler(cancelHandler1)
        .addCancelHandler(cancelHandler2, "text for cancelHandler2")
        .addCancelHandler(TypedPromise<int, int, int>::callbackWithParam(cancelHandler3), 5)
        .delay(3000)
        .then(TypedPromise<int, int, int>::promiseCallback(callback2)) // TypedPromise<int, int, int>::promiseCallback(callback2)
        .catch(catchCallback)
        .error("123")
        .tapCatch(catchCallback)
        .deleteObject(obj)
        .destroy();
};

void callback1(PromiseResolver<int>* resolver) {
    Print("prev: " + "string(prev)");

    Promise::resolve()
        .resolve(231)
        .resolveResolver(resolver, 321)
        .error("123")
        .destroy();
};

void callback2(PromiseResolver<int>* resolver, int prev) {
    Print("prev: " + string(prev));
    resolver.resolve(1);
};

void tapCallback(PromiseResolver<string>* resolver) {
    Print("tapCallback ");
    resolver.resolve();
}

void catchCallback(PromiseResolver<int>* resolver) {
    Print("catchCallback ");
    resolver.resolve(231);
}



void cancelHandler1() {
    Print("cancelHandler1");
}

void cancelHandler2(string text) {
    Print("cancelHandler2", text);
}

void cancelHandler3(int num) {
    Print("cancelHandler2", string(num));
}
