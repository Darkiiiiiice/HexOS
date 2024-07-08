#include <tty/tty.h>

void _kernel_init() {
  
}

void _kernel_main() {
    
    tty_set_theme(TTY_COLOR_GREEN, TTY_COLOR_BLACK);
    tty_put_str("Hello World\n");
    
    for(int i = 0; i < 100; i++) {
        putpixel(i, 100, 0xA0);
    }
  
}
