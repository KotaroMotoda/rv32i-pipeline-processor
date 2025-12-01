#include <stdint.h>

#define LED_ADDR  0x00120000u
#define LED_DELAY 100000u

// 累積和の結果を保存（1,3,6,10,15,21,28,36,45,55）
volatile uint32_t results[10];

static inline void led_write(uint32_t v) {
    *(volatile uint32_t*)(LED_ADDR) = v;  // 32bit 書き込み
}

static inline void delay(void) {
    for (volatile uint32_t d = 0; d < LED_DELAY; ++d) {
        __asm__ volatile ("" ::: "memory");
    }
}

int main(void) {
    uint32_t sum = 0;
    for (uint32_t i = 1; i <= 10; ++i) {
        sum += i;
        results[i - 1] = sum; // 1,3,6,10,15,21,28,36,45,55
        led_write(sum);
        delay();
    }
    while (1) {
        led_write(sum);
        delay();
    }
    return 0;
}