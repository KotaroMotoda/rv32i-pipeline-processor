#include <stdint.h>

#define LED_ADDR        0x00120000u
#define LED_DELAY       150000u
#define LED_PAUSE       600000u
#define LED_MASK        0x00FFFFFFu

static inline void led_write(uint32_t v) {
    *(volatile uint32_t*)(LED_ADDR) = v;
}

static inline void busy_wait(uint32_t loops) {
    for (volatile uint32_t d = 0; d < loops; ++d) {
        __asm__ volatile("nop");
    }
}

int main(void) {
    uint32_t counter = 0;

    while (1) {
        led_write(counter & 0xFFFF);            // 下位16bitだけLEDへ
        counter = (counter + 1) & LED_MASK;     // 24bit カウンタ
        busy_wait(LED_DELAY);                   // 短い待機
        busy_wait(LED_PAUSE);                   // 追加の待機
    }
}
