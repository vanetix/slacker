<template>
<div class="container is-fluid">
  <div class="columns">
    <div class="is-2 column">
      <channel-list
        :current="currentChannel"
        :channels="channels"
        @select="selectChannel"
        @new="createChannel"
        @delete="deleteChannel"/>
    </div>

    <div class="is-8 column">
      <channel-window :messages="currentChannelMessages" @new-message="newMessage"/>
    </div>

    <div class="is-2 column">
      <node-list :socket="phxSocket"/>
    </div>
  </div>
</div>
</template>

<script>
import { Socket } from "phoenix";
import ChannelList from "./components/channel-list.vue";
import ChannelWindow from "./components/channel-window.vue";
import NodeList from "./components/node-list.vue";

export default {
  name: "application",

  components: {
    "channel-list": ChannelList,
    "channel-window": ChannelWindow,
    "node-list": NodeList
  },

  data() {
    return {
      error: null,
      phxSocket: null,
      phxChannel: null,
      currentUser: null,
      channels: [],
      currentChannel: null,
      currentChannelMessages: []
    }
  },

  methods: {
    loadFromLocalStorage() {
      let user = localStorage.getItem("username");

      while (!user) {
        user = window.prompt("Enter username");

        localStorage.setItem("username", user);
      }

      this.currentUser = user;
    },

    initPhoenixChannel() {
      const socket = this.phxSocket = new Socket("/socket");
      const channel = this.phxChannel = socket.channel("chat:lobby");

      socket.connect();
      channel.join();

      channel.on("sync", ({ channels }) => this.channels = channels);
      channel.on("new-channel", ({ name }) => this.channels.push(name));
      channel.on("delete-channel", ({ name }) => {
        const idx = this.channels.findIndex((channel) => name === channel);

        if (idx !== -1) {
          this.$delete(this.channels, idx);
        }
      });
    },

    selectChannel(channel) {
      const oldChannel = this.currentChannel;

      this.leaveChannel(oldChannel);
      this.joinChannel(channel);

      this.currentChannel = channel;
    },

    joinChannel(channel) {
      this.phxChannel.push(`join:${channel}`)
        .receive("ok", ({ messages }) => this.currentChannelMessages = messages);

      this.phxChannel.on(`new-message:${channel}`, (message) => {
        this.currentChannelMessages.push(message);
      });
    },

    leaveChannel(channel) {
      this.phxChannel.off(`new-message:${channel}`);
      this.phxChannel.push(`leave:${channel}`);
    },

    createChannel(channel) {
      this.phxChannel.push("new-channel", channel);
    },

    deleteChannel(channel) {
      this.phxChannel.push("delete-channel", channel);
    },

    newMessage(message) {
      if (this.currentChannel) {
        this.phxChannel.push(`new-message:${this.currentChannel}`, {
          user: this.currentUser,
          body: message
        });
      } else {
        window.alert("No channel selected!");
      }
    }
  },

  created() {
    this.loadFromLocalStorage();
    this.initPhoenixChannel();
  }
};
</script>

<style lang="scss">
$fa-font-path: "~font-awesome/fonts";

@import "~bulma";
@import "~font-awesome/scss/font-awesome.scss";
@import "~styles/variables";

html { height: 100%; }

body {
  padding: 1em 0;
  height: 100%;
  min-height: 100vh;
}

main {
  height: 100%;

  &,
  .panel,
  & > .container,
  & > .container > .columns,
  & > .container > .columns > .column { height: 100%; }
}
</style>
