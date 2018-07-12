// TEST_CONFIG

#include "test.h"
#include <objc/runtime.h>

@interface Super { @public id isa; } @end
@implementation Super 
+(void)initialize { } 
+class { return self; }
+(id) new { return class_createInstance(self, 0); }

-(int)superMethod { return 0; } 
-(int)bothMethod { return 0; } 
@end

@interface Sub : Super @end
@implementation Sub
-(int)subMethod { return 0; }
-(int)bothMethod { return 0; }
@end

@interface Sub2 : Super @end
@implementation Sub2
-(int)subMethod { return 0; }
-(int)bothMethod { return 0; }
@end


id fn(id self __attribute__((unused)), SEL cmd __attribute__((unused)), ...) { return nil; }

int main()
{
    IMP superMethodFromSuper = class_getMethodImplementation([Super class], @selector(superMethod));
    IMP bothMethodFromSuper = class_getMethodImplementation([Super class], @selector(bothMethod));
    IMP subMethodFromSub = class_getMethodImplementation([Sub class], @selector(subMethod));
    IMP bothMethodFromSub = class_getMethodImplementation([Sub class], @selector(bothMethod));
    IMP subMethodFromSub2 = class_getMethodImplementation([Sub2 class], @selector(subMethod));
    IMP bothMethodFromSub2 = class_getMethodImplementation([Sub2 class], @selector(bothMethod));

    testassert(superMethodFromSuper);
    testassert(bothMethodFromSuper);
    testassert(subMethodFromSub);
    testassert(bothMethodFromSub);
    testassert(subMethodFromSub2);
    testassert(bothMethodFromSub2);

    BOOL ok;
    IMP imp;

    // class_addMethod doesn't replace existing implementations
    ok = class_addMethod([Super class], @selector(superMethod), &fn, NULL);
    testassert(!ok);
    testassert(class_getMethodImplementation([Super class], @selector(superMethod)) == superMethodFromSuper);

    // class_addMethod does override superclass implementations
    ok = class_addMethod([Sub class], @selector(superMethod), &fn, NULL);
    testassert(ok);
    testassert(class_getMethodImplementation([Sub class], @selector(superMethod)) == &fn);

    // class_addMethod does add root implementations
    ok = class_addMethod([Super class], @selector(superMethodNew2), &fn, NULL);
    testassert(ok);
    testassert(class_getMethodImplementation([Super class], @selector(superMethodNew2)) == &fn);
    testassert(class_getMethodImplementation([Sub class], @selector(superMethodNew2)) == &fn);


    // class_replaceMethod does add new implementations, 
    // returning NULL if super has an implementation
    imp = class_replaceMethod([Sub2 class], @selector(superMethod), &fn, NULL);
    testassert(imp == NULL);
    testassert(class_getMethodImplementation([Sub2 class], @selector(superMethod)) == fn);

    // class_replaceMethod does add new implementations, 
    // returning NULL if super has no implementation
    imp = class_replaceMethod([Sub2 class], @selector(subMethodNew), &fn, NULL);
    testassert(imp == NULL);
    testassert(class_getMethodImplementation([Sub2 class], @selector(subMethodNew)) == fn);
    
    // class_replaceMethod does add new implemetations
    // returning NULL if there is no super class
    imp = class_replaceMethod([Super class], @selector(superMethodNew), &fn, NULL);
    testassert(imp == NULL);
    testassert(class_getMethodImplementation([Super class], @selector(superMethodNew)) == fn);

    
    // class_replaceMethod does replace existing implementations, 
    // returning existing implementation (regardless of super)
    imp = class_replaceMethod([Sub2 class], @selector(subMethod), &fn, NULL);
    testassert(imp == subMethodFromSub2);
    testassert(class_getMethodImplementation([Sub2 class], @selector(subMethod)) == fn);

    // class_replaceMethod does replace existing implemetations, 
    // returning existing implementation (regardless of super)
    imp = class_replaceMethod([Sub2 class], @selector(bothMethod), &fn, NULL);
    testassert(imp == bothMethodFromSub2);
    testassert(class_getMethodImplementation([Sub2 class], @selector(bothMethod)) == fn);

    // class_replaceMethod does replace existing implemetations, 
    // returning existing implementation (regardless of super)
    imp = class_replaceMethod([Super class], @selector(superMethod), &fn, NULL);
    testassert(imp == superMethodFromSuper);
    testassert(class_getMethodImplementation([Super class], @selector(superMethod)) == fn);

    // fixme actually try calling them

    succeed(__FILE__);
}
