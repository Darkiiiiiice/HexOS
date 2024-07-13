#include <tty/tty.h>

#define TTY_WIDTH 80
#define TTY_HEIGHT 25

uint16_t *buffer = (uint16_t*)0xB8000;

uint16_t theme_color = TTY_COLOR_BLACK;

uint16_t TTY_COLUMN = 0;
uint16_t TTY_ROW = 0;


void tty_set_theme(uint16_t fg, uint16_t bg) {
    theme_color = (bg << 4 | fg) << 8;
}
void tty_put_char(char c){
    uint16_t attr = theme_color | c;
    *(buffer + TTY_COLUMN + TTY_ROW * TTY_WIDTH) = attr;
    TTY_COLUMN++;
    
    if(TTY_COLUMN >= TTY_WIDTH) {
        TTY_COLUMN = 0;
        TTY_ROW++;
        if (TTY_ROW >= TTY_HEIGHT) {
            tty_scroll_up();
            TTY_ROW--;
        }
    }
}

void tty_put_str(char* str) {
    
    while(*str != '\0') {
        tty_put_char(*str);
        str++;
    }
}

void tty_scroll_up() {

}

void tty_clear(){
    
    for( uint16_t x = 0; x < TTY_COLUMN; x++) {
        for(uint16_t y = 0; y < TTY_ROW; y++) {
            *(buffer + x + y * TTY_WIDTH) = theme_color;
        }
    }
}

/* example for 320x200 VGA */
void putpixel(int pos_x, int pos_y, unsigned char VGA_COLOR)
{
    unsigned char* location = (unsigned char*)0xA0000 + 320 * pos_y + pos_x;
    *location = VGA_COLOR;
}