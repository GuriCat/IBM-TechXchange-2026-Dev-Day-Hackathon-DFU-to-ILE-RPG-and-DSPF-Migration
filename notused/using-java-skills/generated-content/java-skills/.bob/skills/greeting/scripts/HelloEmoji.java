//DEPS com.vdurmont:emoji-java:5.1.0

import com.vdurmont.emoji.EmojiParser;

public class HelloEmoji {
    public static void main(String[] args) {
        String msg = "Aloha :smiley:";
        System.out.println(EmojiParser.parseToUnicode(msg));
    } 
}
