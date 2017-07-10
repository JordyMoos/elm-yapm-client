const webpack = require('webpack');
var merge = require('webpack-merge');
var CopyWebpackPlugin = require('copy-webpack-plugin');
var HTMLWebpackPlugin = require('html-webpack-plugin');
var HtmlWebpackInlineSourcePlugin = require('html-webpack-inline-source-plugin');
var WebpackPwaManifest = require('webpack-pwa-manifest');
var path = require('path');

var TARGET_ENV = process.env.npm_lifecycle_event === 'prod'
    ? 'production'
    : 'development';
var filename = (TARGET_ENV == 'production')
    ? 'remove-me.js'
    : 'index.js';

var common = {
    entry: './src/static/index.js',
    output: {
        path: path.join(__dirname, "dist"),
        // add hash when building for production
        filename: filename
    },
    plugins: [
        new HTMLWebpackPlugin({
            // using .ejs prevents other loaders causing errors
            template: 'src/static/index.ejs',
            // inject details of output file at end of body
            inject: 'body',
            inlineSource: '.(js|css)$'
        }),
        new WebpackPwaManifest({
            name: 'Yet Another Password Manager',
            short_name: 'Passwords',
            display: 'fullscreen',
            orientation: 'portrait',
            background_color: '#ffffff',
            icons: [
                {
                    src: path.resolve('src/static/assets/img/favicon.png'),
                    sizes: [96, 128, 192, 256, 384, 512] // multiple sizes
                }
            ]
        })
    ],
    resolve: {
        modules: [
            path.join(__dirname, "src"),
            "node_modules"
        ],
        extensions: ['.js', '.elm', '.scss', '.png']
    },
    module: {
        rules: [
            {
                test: /\.html$/,
                exclude: /node_modules/,
                loader: 'file-loader?name=[name].[ext]'
            }, {
                test: /\.js$/,
                exclude: /node_modules/,
                use: {
                    loader: 'babel-loader',
                    options: {
                        // env: automatically determines the Babel plugins you need based on your supported environments
                        presets: ['env']
                    }
                }
            }, {
                test: /\.scss$/,
                exclude: [
                    /elm-stuff/, /node_modules/
                ],
                loaders: ["style-loader", "css-loader", "sass-loader"]
            }, {
                test: /\.css$/,
                exclude: [
                    /elm-stuff/, /node_modules/
                ],
                loaders: ["style-loader", "css-loader"]
            }, {
                test: /\.woff(2)?(\?v=[0-9]\.[0-9]\.[0-9])?$/,
                exclude: [
                    /elm-stuff/, /node_modules/
                ],
                loader: "url-loader",
                options: {
                    limit: 10000,
                    mimetype: "application/font-woff"
                }
            }, {
                test: /\.(ttf|eot|svg)(\?v=[0-9]\.[0-9]\.[0-9])?$/,
                exclude: [
                    /elm-stuff/, /node_modules/
                ],
                loader: "url-loader"
            }, {
                test: /\.(jpe?g|png|gif|svg)$/i,
                loader: 'url-loader'
            }
        ]
    }
}

if (TARGET_ENV === 'development') {
    console.log('Building for dev...');
    module.exports = merge(common, {
        plugins: [
            // Suggested for hot-loading
            new webpack.NamedModulesPlugin(),
            // Prevents compilation errors causing the hot loader to lose state
            new webpack.NoEmitOnErrorsPlugin()
        ],
        module: {
            rules: [
                {
                    test: /\.elm$/,
                    exclude: [
                        /elm-stuff/, /node_modules/
                    ],
                    use: [
                        {
                            loader: "elm-hot-loader"
                        }, {
                            loader: "elm-webpack-loader",
                            // add Elm's debug overlay to output
                            options: {
                                debug: true
                            }
                        }
                    ]
                }
            ]
        },
        devServer: {
            inline: true,
            stats: 'errors-only',
            contentBase: path.join(__dirname, "src/static/assets")
        }
    });
}

if (TARGET_ENV === 'production') {
    console.log('Building for prod...');
    module.exports = merge(common, {
        plugins: [
            new webpack.optimize.UglifyJsPlugin(),
            new HtmlWebpackInlineSourcePlugin()
        ],
        module: {
            rules: [
                {
                    test: /\.elm$/,
                    exclude: [
                        /elm-stuff/, /node_modules/
                    ],
                    use: [
                        {
                            loader: "elm-webpack-loader"
                        }
                    ]
                }
            ]
        }
    });
}
