<template>
<nav class="panel">
  <p class="panel-heading">
    Nodes
  </p>

  <div v-for="node in nodes" :key="node.name"
    :class="{ 'panel-block': true, active: node.active }">
    <span>{{ node.name }}</span>
  </div>
</nav>
</template>

<script>
import { Socket } from "phoenix";

export default {
  name: "node-list",
  props: ["socket"],

  data() {
    return {
      nodes: []
    };
  },

  created() {
      const channel = this.socket.channel("nodes:lobby");

      channel.join();

      channel.on("nodes", ({ nodes }) => {
        this.$set(this, "nodes", nodes.sort());
      });
  }
};
</script>

<style scoped lang="scss">
@import "~styles/variables";

.panel-block.active span {
  position: relative;

  &:after {
    position: absolute;
    bottom: -2px;
    left: 0;
    right: 0;
    content: "";
    border-bottom: 2px solid lighten($cyan, 20%);
  }
}
</style>
