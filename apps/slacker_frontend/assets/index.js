import Vue from 'vue'
import Application from './application.vue';

const App = new Vue({
  el:'#vue-app',
  name: 'App',
  render: h => h(Application)
})

