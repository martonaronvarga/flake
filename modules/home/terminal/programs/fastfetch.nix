let
  logo = builtins.path {
    path = ../../../../assets/fastfetch/snowflake.txt;
    name = "snowflake.txt";
  };
in {
  xdg.configFile."fastfetch/config.jsonc".text = ''
    {
      "$schema": "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json",

      "logo": {
        "type": "file",
        "source": "${logo}",
        "color": {
          "1": "cyan"
        },
        "padding": {
          "right": 3
        }
      },

      "display": {
        "separator": "  ",
        "brightColor": false,

        "color": {
          "title": "cyan",
          "keys": "cyan",
          "separator": "bright_black",
          "output": "white"
        },

        "key": {
          "type": "string",
          "width": 3
        },

        "duration": {
          "abbreviation": true
        },

        "size": {
          "binaryPrefix": "iec",
          "maxPrefix": "GB",
          "ndigits": 2
        },

        "bar": {
          "width": 15,
          "char": {
            "elapsed": "-",
            "total": "="
          },
          "border": {
            "left": "[",
            "right": "]"
          },
          "color": {
            "elapsed": "cyan",
            "total": "cyan",
            "border": "cyan"
          }
        }
      },

      "modules": [
        {
          "type": "title",
          "color": {
            "user": "cyan",
            "at": "cyan",
            "host": "cyan"
          }
        },
        {
          "type": "separator",
          "string": "─",
          "outputColor": "bright_black"
        },
        {
          "type": "os",
          "key": "",
          "format": "{pretty-name}"
        },
        {
          "type": "kernel",
          "key": "",
          "format": "{sysname} {release}"
        },
        {
          "type": "uptime",
          "key": ""
        },
        {
          "type": "packages",
          "key": ""
        },
        {
          "type": "wm",
          "key": ""
        },
        {
          "type": "shell",
          "key": ""
        },
        {
          "type": "memory",
          "key": "󰇂",
          "format": "{used} / {total}"
        }
      ]
    }
  '';
}
