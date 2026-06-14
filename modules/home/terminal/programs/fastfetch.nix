let
  image = builtins.path {
    path = ../../../../assets/wallpapers/snowflake.jpg;
    name = "snowflake.jpg";
  };
in {
  xdg.configFile."fastfetch/config.jsonc".text = ''
    {
      "$schema": "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json",

      "logo": {
        "type": "kitty",
        "source": "${image}",
        "padding": {
          "right": 5
        },
        "printRemaining": false
      },

      "display": {
        "separator": " • ",
        "brightColor": false,

        "color": {
          "title": "cyan",
          "keys": "magenta",
          "separator": "light_yellow",
          "output": "light_yellow"
        },

        "key": {
          "type": "string",
          "width": 2
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
          "outputColor": "light_yellow"
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
