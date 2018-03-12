<template>
<nav class="panel">
  <p class="panel-heading">
    Channels
  </p>

  <div class="panel-block">
    <p class="control has-icons-right">
      <input class="input is-small" type="text" placeholder="create..."
        v-model="channelName"
        @keyup.enter="emitCreate"/>

      <span class="icon is-small is-right">
        <i class="fa fa-plus"></i>
      </span>
    </p>
  </div>

  <a
    v-for="channel in sortedChannels"
    :key="channel"
    @click="emitSelect(channel)"
    :class="classesForBlock(channel)">
    <span>{{ channel }}</span>
    <span class="delete is-small" @click.prevent.stop="emitDelete(channel)"></span>
  </a>
</nav>
</template>

<script>
export default {
  name: "channel-list",
  props: ["channels", "current"],

  data() {
    return {
      channelName: ""
    };
  },

  computed: {
    sortedChannels() {
      return this.channels.sort();
    }
  },

  methods: {
    emitCreate() {
      this.$emit("new", this.channelName);
      this.channelName = "";
    },

    emitDelete(channel) {
      this.$emit("delete", channel);
    },

    emitSelect(channel) {
      if (channel !== this.current) {
        this.$emit("select", channel);
      }
    },

    classesForBlock(name) {
      return {
        "panel-block": true,
        "channel": true,
        "is-active": name === this.current
      };
    }
  }
};
</script>

<style scoped lang="scss">
@import "~styles/variables";

.channel {
  position: relative;

  .delete {
    position: absolute;
    right: 6px;
  }
}
</style>
