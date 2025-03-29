#ifdef mql5PromiseDev
   #include "../node_modules/mql5-timer/index.mqh";
#else
   #include "../../mql5-timer/index.mqh";
#endif

#include "Callback.mqh";
#include "DeleteObjectContainer.mqh";
#include "BasePromise.mqh";
#include "PromiseResolver.mqh";
#include "TypedPromise.mqh";
#include "Promise.mqh";
