#include <stdint.h>

#define LED_ADDR  0x00120000u
#define LED_DELAY 100000u

// 24bitカウンタにして,上位8bitを,LEDに出力する. 

// 累積和の結果を保存（1,3,6,10,15,21,28,36,45,55）=> 
volatile uint32_t results[10];

static inline void led_write(uint32_t v) {
    *(volatile uint32_t*)(LED_ADDR) = v;  // 32bit 書き込み
}

int main(void) {
    short cnt;
    cnt = 0;
    while(1){
        cnt ++ ;
        led_write(cnt);
        for(volatile uint32_t d = 0; d < LED_DELAY; d++); // 遅延
    }
}
