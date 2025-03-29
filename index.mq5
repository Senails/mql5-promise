#define mql5PromiseDev "";
#include "src/index.mqh";

void OnInit() {
    Print("start");

    BasePromiseDeleteObjectContainer* obj = new BasePromiseDeleteObjectContainer();

    Promise::try(TypedPromise<int, int, int>::promiseCallback(callback1))
        .tap(tapCallback)
        .delay(3000)
        .executeSyncCallback(syncCallback)
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
        .returnDefaultPromise()
        .error("123")
        .catchReturn("123", "param for returnCatchCallback")
        .then(returnCatchCallback)
        .destroy();
};


void returnCatchCallback(PromiseResolver<string>* resolver, string prev) {
    Print("returnCatchCallback: " + prev);
    resolver.resolve();
}


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

void syncCallback() {
    Print("syncCallback");

    Promise::resolve()
        .addCancelHandler(cancelHandler1)
        .addCancelHandler(cancelHandler2, "text for cancelHandler2")
        .addCancelHandler(TypedPromise<int, int, int>::callbackWithParam(cancelHandler3), 5)
        .destroy();
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
