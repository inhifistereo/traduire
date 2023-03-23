const webpack = require('webpack');
/*
module.exports = function override(config, env) {
    config.resolve.fallback = {
        url: require.resolve('url'),
        util: require.resolve('util'),
        stream: require.resolve('stream'),
        assert: require.resolve('assert'),
        crypto: require.resolve('crypto-browserify'),
        buffer: require.resolve('buffer')
    };
    return config;
}*/

module.exports = {
    resolve: {
        fallback: {
            url: require.resolve('url'),
            util: require.resolve('util'),
            stream: require.resolve('stream'),
            assert: require.resolve('assert'),
            crypto: require.resolve('crypto-browserify'),
            buffer: require.resolve('buffer'),          
        },
        alias: {
            process: 'process/browser',
        },
    },
    plugins: [
        new webpack.ProvidePlugin({
          process: 'process/browser',
        }),
        new webpack.DefinePlugin({
            'process.version': '16.0',
        }),
    ]
}