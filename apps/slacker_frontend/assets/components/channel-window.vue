<template>
<div class="box">
  <div class="history">

    <article class="media"
      v-for="message in messages"
      :key="message.sent_at">
      <div class="media-content">
        <div class="content is-info">
          <p>
            <strong>{{ message.user }}</strong>
            <br>
            {{ message.body }}
          </p>
        </div>
      </div>

      <div class="media-right">
        <time :datetime="message.sent_at">{{ formatTimestamp(message.sent_at) }}</time>
      </div>
    </article>
  </div>

  <div class="new-message">
    <form @submit.prevent="emitNewMessage">
      <div class="field has-addons">
        <div class="control is-expanded">
          <input
            v-model="message"
            class="input" type="text" placeholder="Type your message..."/>
        </div>

        <div class="control">
          <input class="button is-info" type="submit" value="Send"/>
        </div>
      </div>
    </form>
  </div>
</div>
</template>

<script>
import moment from "moment";

export default {
  name: "channel-window",
  props: ["messages"],

  data() {
    return {
      message: ""
    };
  },

  methods: {
    emitNewMessage() {
      if (this.message !== "") {
        this.$emit("new-message", this.message);
        this.message = "";
      }
    },

    formatTimestamp(str) {
      const time = moment.utc(str);

      return time.fromNow();
    }
  },

  updated() {
    let messagePane = this.$el.querySelector(".history")

    messagePane.scrollTop = messagePane.scrollHeight;
  }
};
</script>

<style scoped lang="scss">
@import "~styles/variables";

.box {
  display: flex;
  flex-direction: column;
  height: 100%;
  overflow: hidden;
  padding: 0;
}

.history {
  overflow-y: auto;
  flex-grow: 1;
  padding: 0.4em 0.6em;

  .media {
    margin-top: 0.8em;
    padding: 0.2em 0.4em;
    background: $message-box;
    border-radius: 4px;
    border: 1px solid darken($border, 20%);
    color: $black;
    box-shadow: 2px 2px 1px 0 darken($border, 4%);

    &:first-child { margin-top: 0; }

    time { font-size: 0.8em; }

    strong {
      display: inline-block;
      margin: 0 0 0.2em 0;
      border-bottom: 1px dotted $border;
    }
  }
}

.new-message {
  margin: 0.4em 0 0 0;
  border-top: 1px solid $border;

  input,
  input:active,
  input:focus {
    border: none;
    box-shadow: none !important;
    border-radius: 0;
  }
}
</style>
