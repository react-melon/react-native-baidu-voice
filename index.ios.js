/**
 * Sample React Native App
 * https://github.com/facebook/react-native
 */
'use strict';

var React = require('react-native');
var {
  AppRegistry,
  StyleSheet,
  Text,
  View,
  NativeModules,
  NativeAppEventEmitter,
  TouchableHighlight
} = React;

var {RNBaiduVoice} = NativeModules;

var styles;

var reactNativeBaiduVoice = React.createClass({
    componentDidMount() {
        this.subscription = NativeAppEventEmitter.addListener(
            'RecognitionEvent',
            this.onRecognitionEvent.bind(this)
        );
    },
    componentWillUnmount() {
        this.subscription.remove();
    },
    onPressIn() {
        RNBaiduVoice.startRecognition();
    },
    onPressOut() {
        RNBaiduVoice.finishRecognition();
    },
    onRecognitionEvent(e) {
        console.log(e);
        if (e.type === 'finish' || e.type === 'processing') {
            this.setState({result: e.result});
        }
    },
    getInitialState() {
        return {
            result: ''
        };
    },
    render() {
        return (
            <View style={styles.container}>
                <TouchableHighlight onPressIn={this.onPressIn} onPressOut={this.onPressOut}>
                    <Text style={styles.welcome}>识别开始</Text>
                </TouchableHighlight>
                <View>
                    <Text style={styles.instructions}>{this.state.result}</Text>
                </View>
            </View>
        );
    }
});

styles = StyleSheet.create({
    container: {
        flex: 1,
        justifyContent: 'center',
        alignItems: 'center',
        backgroundColor: '#F5FCFF'
    },
    welcome: {
        fontSize: 20,
        textAlign: 'center',
        margin: 10
    },
    instructions: {
        textAlign: 'center',
        color: '#333333',
        marginBottom: 5
    }
});

AppRegistry.registerComponent('reactNativeBaiduVoice', () => reactNativeBaiduVoice);
