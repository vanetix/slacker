<template>
<nav class="panel">
  <p class="panel-heading">
    Nodes
  </p>

  <div class="panel-block" v-for="node in nodes" :key="node">
    <span>{{ node }}</span>
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

<style lang="scss">
@import "~styles/variables";

</style>
