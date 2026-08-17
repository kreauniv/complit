from pygments.style import Style
from pygments.token import (
    Text,
    Keyword,
    Name,
    Comment,
    String,
    Error,
    Number,
    Operator,
    Generic,
)


class sricodeStyle(Style):
    default_style = ""
    styles = {
        Text: "#000000",
        Comment: "#008426",
        String: "#D92823",
        Number: "#2F2ECF",
        Keyword: "bold #000000",
        Name.Class: "#753EA3",
    }
