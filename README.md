An interface for implementing asynchronous execution of algorithms for mql5, like Promise in JavaScript.

Example Promise :

```mql5
void OnInit() {
    new Promise(printAndTimoutResolve, "111")
        .then(printAndReject, "222") // then - run if prev promise is resolved
        .ccatch(printAndResolve, "333") // ccatch - run if prev promise is rejected
        .ccatch(printAndResolve, "444")
        .ccatch(printAndResolve, "555")
        .then(printAndResolve, "666")
        .finally(printAndResolve, "end") // finally - run anything
        .destroy(); // clear memory theese promises after execution all promises

    Print("start");

    // printAndTimoutResolve 111   // timeout after Print
    // start
    // printAndReject 222
    // printAndTimoutResolve 333
    // printAndTimoutResolve 666
    // printAndTimoutResolve end
};

void promiseAllResolve(ulong promiseId, string &prevResult[], string parametr) {
    Print("promiseAllResolve " + parametr);
};

void printAndTimoutResolve(ulong promiseId, string prevResult, string parametr) {
    Print("printAndTimoutResolve " + parametr);
    Timer::setTimout(resolveByIdStr, 2000, string(promiseId));
};
void resolveByIdStr(string id) { Promise::resolveById(ulong(id)); }

void printAndResolve(ulong promiseId, string prevResult, string parametr) {
    Print("printAndResolve " + parametr);
    Promise::resolveById(promiseId);
};

void printAndReject(ulong promiseId, string prevResult, string parametr) {
    Print("printAndReject " + parametr);
    Promise::rejectById(promiseId);
};
```

Example Promise:all :

```mql5
void OnInit() {
    Promise* list1[] = {
        new Promise(printAndTimoutResolve, "Promise 1")
            .then(printAndTimoutResolve, "Promise 1.1")
        ,
        new Promise(printAndReject, "Promise 2"),
        new Promise(printAndTimoutResolve, "Promise 3"),
    };

    Promise::all(list1, promiseAllResolve) // resolve if all promises are resolved
        .then(printAndResolve, "Promise::all resolved")
        .ccatch(printAndResolve, "Promise::all rejected")
        .destroy(); // delete all promises

    // printAndTimoutResolve Promise 1
    // printAndReject Promise 2
    // printAndTimoutResolve Promise 3
    // printAndResolve Promise::all rejected
};
```

Example Promise:race :

```mql5
void OnInit() {
    Promise* list2[] = {
        new Promise(printAndTimoutResolve, "Promise 1")
            .then(printAndTimoutResolve, "Promise 1.1")
        ,
        new Promise(printAndReject, "Promise 2"),
        new Promise(printAndTimoutResolve, "Promise 3"),
    };

    Promise::race(list2, printAndResolve, "Promise::race") // resolve/reject after the first promise
        .then(printAndResolve, "Promise::race resolved")
        .ccatch(printAndResolve, "Promise::race rejected")
        .destroy();

    // printAndTimoutResolve Promise 1
    // printAndReject Promise 2
    // printAndTimoutResolve Promise 3
    // Promise::race rejected
};
```

Example Promise:any :

```mql5
void OnInit() {
    Promise* list3[] = {
        new Promise(printAndTimoutResolve, "Promise 1")
            .then(printAndTimoutResolve, "Promise 1.1")
        ,
        new Promise(printAndReject, "Promise 2"),
        new Promise(printAndTimoutResolve, "Promise 3"),
    };

    Promise::any(list3, printAndResolve, "Promise::any")
        .then(printAndResolve, "Promise::any resolved")
        .ccatch(printAndResolve, "Promise::any rejected")
        .destroy();

    // printAndTimoutResolve Promise 1
    // printAndReject Promise 2
    // printAndTimoutResolve Promise 3
    // printAndResolve Promise::any
    // printAndResolve Promise::any resolved
};
```
