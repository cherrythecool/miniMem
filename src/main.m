#include <AppKit/AppKit.h>
#include <Foundation/Foundation.h>
#include <MacTypes.h>

#include <stdlib.h>
#include <stddef.h>
#include <stdio.h>
#include <stdbool.h>

// undocumented sys call that's alledgedly used by activity monitor LOL
extern int memorystatus_get_level(int *level);

// Returns -1 on failure
// Returns percentage 0 - 100 as an integer
static int get_memory_pressure(void) {
    int level = 0;
    int result = memorystatus_get_level(&level);

    if (result == 0) {
        return level;
    } else {
        return -1;
    }
}

static NSImage* setup_image(NSString* string, CGFloat size) {
    NSBundle *main_bundle = [NSBundle mainBundle];
    [main_bundle autorelease];

    NSString *image_path = [main_bundle pathForResource:string ofType:@"svg"];
    [image_path autorelease];

    NSImage* image = [[NSImage alloc] initWithContentsOfFile:image_path];

    [image setTemplate:NO];
    [image setSize:NSMakeSize(size, size)];
    [image autorelease];
    return image;
}

#define PAIR_COUNT 3

struct ImagePair {
    NSImage* source;
    int pressure_maximum;
};

static NSImage* choose_image(int pressure, struct ImagePair* pairs, size_t pairs_size) {
    NSImage* chosen;

    for (size_t i = 0; i < pairs_size; i++) {
        struct ImagePair pair = pairs[i];
        if (pressure <= pair.pressure_maximum) {
            chosen = pair.source;
        } else {
            break;
        }
    }

    return chosen;
}

static NSString* get_percentage_string(int percentage) {
    char* args = (char*)&percentage;
    NSString* string = [[NSString alloc] initWithFormat:@"%d%% Memory Free" arguments:args];
    [string autorelease];
    return string;
}

int main(void) {
    [NSApplication sharedApplication];
    [NSApp setActivationPolicy:NSApplicationActivationPolicyAccessory];

    NSStatusBar* bar = [NSStatusBar systemStatusBar];
    NSStatusItem* item = [bar statusItemWithLength:NSSquareStatusItemLength];

    NSStatusBarButton* button = item.button;

    NSMenu* menu = [[NSMenu alloc] init];
    [menu autorelease];
    [menu addItemWithTitle:@"⌘ miniMem" action:nil keyEquivalent:@""];

    NSMenuItem* percentage = [[NSMenuItem alloc] init];
    [percentage autorelease];
    [menu addItem:percentage];

    [menu addItem:[NSMenuItem separatorItem]];
    [menu addItemWithTitle:@"Quit" action:@selector(terminate:) keyEquivalent:@""];

    [item setMenu:menu];

    CGFloat thickness = [bar thickness];

    NSImage* low_pressure = setup_image(@"low_pressure", thickness);
    NSImage* medium_pressure = setup_image(@"medium_pressure", thickness);
    NSImage* high_pressure = setup_image(@"high_pressure", thickness);

    struct ImagePair pairs[PAIR_COUNT] = {
        {
            low_pressure,
            100,
        },
        {
            medium_pressure,
            40,
        },
        {
            high_pressure,
            10
        }
    };
    struct ImagePair* pairsPtr = pairs;

    __block int memory_pressure = get_memory_pressure();
    button.image = choose_image(memory_pressure, pairs, PAIR_COUNT);
    percentage.title = get_percentage_string(memory_pressure);

    NSTimer* timer = [NSTimer scheduledTimerWithTimeInterval:1
                                repeats:YES
                                block:^(NSTimer* timer) {
                                    int last_pressure = memory_pressure;
                                    memory_pressure = get_memory_pressure();

                                    if (memory_pressure != last_pressure) {
                                        percentage.title = get_percentage_string(memory_pressure);
                                    }

                                    NSImage* chosen_image = choose_image(memory_pressure, pairsPtr, PAIR_COUNT);
                                    if (button.image != chosen_image) {
                                        button.image = chosen_image;
                                    }
                                }];

    [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];

    while (true) {
        @autoreleasepool {
            NSEvent *event;
            if ((event = [NSApp nextEventMatchingMask:NSEventMaskAny
                                untilDate:([NSDate distantFuture])
                                inMode:NSDefaultRunLoopMode
                                dequeue:YES]) != nil) {
                [NSApp sendEvent:event];
            }
        }
    }

    return EXIT_SUCCESS;
}