#ifdef mql5PromiseDev
   #include "../node_modules/mql5-timer/index.mqh";
#else
   #include "../../mql5-timer/index.mqh";
#endif

#include "Callbacks.mqh";
#include "Containers.mqh";
#include "BasePromise.mqh";
#include "PromiseResolver.mqh";
#include "TypedPromise.mqh";
#include "Promise.mqh";
