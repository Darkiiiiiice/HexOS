#include <tty/tty.h>

void _kernel_init() {
  
}

extern int cpu_id();
void _kernel_main(uint32_t magic, uint32_t addr) {
    int a = cpu_id();
    int b = a;
    int c= a;
    a++;
    
    
    tty_set_theme(TTY_COLOR_GREEN, TTY_COLOR_BLACK);
    tty_put_str("Hello World\n");
    
    for(int i = 0; i < 100; i++) {
        putpixel(i, 100, 0xA0);
    }
  
}
