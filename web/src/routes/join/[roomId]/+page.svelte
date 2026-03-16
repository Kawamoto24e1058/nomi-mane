<script lang="ts">
  // @ts-nocheck
// @ts-ignore
  import { db } from "$lib/firebase";
// @ts-ignore
  import { doc, getDoc, collection, addDoc, serverTimestamp } from "firebase/firestore";
// @ts-ignore
  import { page } from "$app/stores";
// @ts-ignore
  import { onMount } from "svelte";
// @ts-ignore
  import { goto } from "$app/navigation";
// @ts-ignore
  import { browser } from "$app/environment";

  const roomId = $page.params.roomId;
  let roomData: any = null;
  let name = "";
  let paymentMethod: "paypay" | "bank" | "cash" = "paypay";
  let isLoading = false;

  onMount(async () => {
    const docRef = doc(db, "rooms", roomId);
    const docSnap = await getDoc(docRef);
    if (docSnap.exists()) {
      roomData = docSnap.data();
    } else {
      goto("/");
    }
  });

  async function join() {
    if (!name) return;
    isLoading = true;
    try {
      await addDoc(collection(db, "rooms", roomId, "guests"), {
        name,
        paymentMethod,
        status: "waiting",
        actualFee: roomData.baseFee,
        joinedAt: serverTimestamp()
      });

      if (browser) {
        localStorage.setItem("nomimane_name", name);
      }
      
      goto(`/payment/${roomId}?method=${paymentMethod}`);
    } catch (e) {
      console.error(e);
    } finally {
      isLoading = false;
    }
  }

  onMount(() => {
    if (browser) {
      name = localStorage.getItem("nomimane_name") || "";
    }
  });
</script>

<svelte:head>
  <title>チェックイン - 飲みマネ</title>
</svelte:head>

<main class="max-w-md mx-auto px-6 py-8">
  <div class="text-center mb-10">
    <h1 class="text-2xl font-black text-paypay-red italic mb-1">飲みマネ</h1>
    {#if roomData}
      <p class="text-gray-500 font-bold text-sm">「{roomData.hostName}」さんの飲み会</p>
    {/if}
  </div>

  {#if roomData}
    <div class="bg-white p-6 rounded-3xl shadow-lg border border-gray-50 mb-8">
      <div class="text-center mb-6">
        <p class="text-xs font-bold text-gray-400 mb-1">会費（一人あたり）</p>
        <p class="text-3xl font-black text-gray-800">¥{roomData.baseFee.toLocaleString()}</p>
      </div>

      <div class="space-y-6">
        <label class="block">
          <span class="text-xs font-bold text-gray-500 ml-1">お名前</span>
          <input
            type="text"
            bind:value={name}
            placeholder="例: たろう"
            class="mt-1 block w-full px-4 py-3 bg-gray-50 border-none rounded-xl focus:ring-2 focus:ring-paypay-red focus:bg-white outline-none font-bold"
          />
        </label>

        <div>
          <span class="text-xs font-bold text-gray-500 ml-1">支払い方法の選択</span>
          <div class="grid grid-cols-1 gap-3 mt-1">
            <button
              on:click={() => paymentMethod = "paypay"}
              class="flex items-center justify-between p-4 rounded-xl border-2 transition-all {paymentMethod === 'paypay' ? 'border-paypay-red bg-red-50' : 'border-gray-50 bg-gray-50'}"
            >
              <span class="font-bold {paymentMethod === 'paypay' ? 'text-paypay-red' : 'text-gray-600'}">PayPay</span>
              <div class="w-5 h-5 rounded-full border-2 flex items-center justify-center {paymentMethod === 'paypay' ? 'border-paypay-red' : 'border-gray-300'}">
                {#if paymentMethod === 'paypay'}
                  <div class="w-2.5 h-2.5 rounded-full bg-paypay-red"></div>
                {/if}
              </div>
            </button>

            <button
              on:click={() => paymentMethod = "bank"}
              class="flex items-center justify-between p-4 rounded-xl border-2 transition-all {paymentMethod === 'bank' ? 'border-paypay-red bg-red-50' : 'border-gray-50 bg-gray-50'}"
            >
              <span class="font-bold {paymentMethod === 'bank' ? 'text-paypay-red' : 'text-gray-600'}">銀行振込 / ことら送金</span>
              <div class="w-5 h-5 rounded-full border-2 flex items-center justify-center {paymentMethod === 'bank' ? 'border-paypay-red' : 'border-gray-300'}">
                {#if paymentMethod === 'bank'}
                  <div class="w-2.5 h-2.5 rounded-full bg-paypay-red"></div>
                {/if}
              </div>
            </button>

            <button
              on:click={() => paymentMethod = "cash"}
              class="flex items-center justify-between p-4 rounded-xl border-2 transition-all {paymentMethod === 'cash' ? 'border-paypay-red bg-red-50' : 'border-gray-50 bg-gray-50'}"
            >
              <span class="font-bold {paymentMethod === 'cash' ? 'text-paypay-red' : 'text-gray-600'}">現金</span>
              <div class="w-5 h-5 rounded-full border-2 flex items-center justify-center {paymentMethod === 'cash' ? 'border-paypay-red' : 'border-gray-300'}">
                {#if paymentMethod === 'cash'}
                  <div class="w-2.5 h-2.5 rounded-full bg-paypay-red"></div>
                {/if}
              </div>
            </button>
          </div>
        </div>
      </div>
    </div>

    <button
      on:click={join}
      disabled={!name || isLoading}
      class="btn-primary w-full h-14 text-lg"
    >
      参加する
    </button>
  {:else}
    <div class="mt-20 text-center text-gray-400">
      <div class="animate-spin text-3xl mb-4">🌀</div>
      <p class="text-sm font-medium">チェックイン情報を読み込み中...</p>
    </div>
  {/if}
</main>
