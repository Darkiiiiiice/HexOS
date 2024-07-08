#include <stdint.h>

#define TTY_COLOR_BLACK 0x0
#define TTY_COLOR_BLUE 0x1
#define TTY_COLOR_GREEN 0x2
#define TTY_COLOR_CYAN 0x3
#define TTY_COLOR_RED 0x4
#define TTY_COLOR_MAGENTA 0x5
#define TTY_COLOR_BROWN 0x6
#define TTY_COLOR_LIGHT_GREY 0x7
#define TTY_COLOR_DARK_GREY 0x8
#define TTY_COLOR_LIGHT_BLUE 0x9
#define TTY_COLOR_LIGHT_GREEN 0xa
#define TTY_COLOR_LIGHT_CYAN 0xb
#define TTY_COLOR_LIGHT_RED 0xc
#define TTY_COLOR_LIGHT_MAGENTA 0xd
#define TTY_COLOR_LIGHT_BROWN 0xe
#define TTY_COLOR_WHITE 0xf

void tty_set_theme(uint16_t fg, uint16_t bg);

void tty_put_char(char c);

void tty_put_str(char* str);

void tty_scroll_up();

void tty_clear();

void putpixel(int pos_x, int pos_y, unsigned char VGA_COLOR);