#include <stdint.h>

// 累積和の結果を保存（1,3,6,10,15,21,28,36,45,55）
volatile uint32_t results[10];

// 必要なら LED にも出したい場合は、正しい物理アドレスを定義してビルドしてください。
// 例: -DLED_ADDR=0xXXXXXXXX
static inline void led_write(uint32_t v) {
#ifdef LED_ADDR
    *(volatile uint32_t*)(LED_ADDR) = v;
#else
    (void)v;
#endif
}

int main(void) {
    uint32_t sum = 0;
    for (uint32_t i = 1; i <= 10; ++i) {
        sum += i;
        results[i - 1] = sum; // 1,3,6,10,15,21,28,36,45,55
        led_write(sum);       // LED_ADDR 定義時のみ出力
        // 遅延が必要なら簡易ウェイトを入れてください（例: for(volatile int d=0; d<100000; ++d){}）
    }
    return 0;
}