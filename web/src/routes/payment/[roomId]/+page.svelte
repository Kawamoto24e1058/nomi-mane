<script lang="ts">
  // @ts-nocheck
  import { db } from "$lib/firebase";
  import { doc, getDoc, deleteDoc, collection, query, where, getDocs, onSnapshot, updateDoc } from "firebase/firestore";
  import { page } from "$app/stores";
  import { onMount, onDestroy } from "svelte";
  import { CheckCircle2, ExternalLink, LogOut, Circle, X } from "lucide-svelte";
  import { browser } from "$app/environment";
  import { goto } from "$app/navigation";

  const roomId = $page.params.roomId;
  let method = $page.url.searchParams.get("method");
  let roomData: any = null;
  let guestData: any = null;
  let unsubscribeGuest: any = null;

  let showMethodModal = false;

  onMount(async () => {
    // Subscribe to Room Data
    const roomRef = doc(db, "rooms", roomId);
    onSnapshot(roomRef, (s) => {
      roomData = s.data();
    });

    // Subscribe to Guest Data (this user)
    if (browser) {
      const name = localStorage.getItem("nomimane_name");
      if (name) {
        const guestsRef = collection(db, "rooms", roomId, "guests");
        const q = query(guestsRef, where("name", "==", name));
        
        // Use onSnapshot for real-time fee updates
        unsubscribeGuest = onSnapshot(q, (snapshot) => {
          if (!snapshot.empty) {
            guestData = { id: snapshot.docs[0].id, ...snapshot.docs[0].data() };
          }
        });
      }
    }
  });

  onDestroy(() => {
    if (unsubscribeGuest) unsubscribeGuest();
  });

  async function leaveRoom() {
    if (!browser) return;
    
    const name = localStorage.getItem("nomimane_name");
    if (!name) {
      goto("/");
      return;
    }

    if (confirm("このルームから退出しますか？参加データは削除されます。")) {
      try {
        // Find guest doc by name (simple approach for MVP)
        const guestsRef = collection(db, "rooms", roomId, "guests");
        const q = query(guestsRef, where("name", "==", name));
        const querySnapshot = await getDocs(q);
        
        const deletePromises = querySnapshot.docs.map(d => deleteDoc(d.ref));
        await Promise.all(deletePromises);
        
        localStorage.removeItem("nomimane_name");
        goto("/");
      } catch (e) {
        console.error("Error leaving room:", e);
        alert("退出に失敗しました。");
      }
    }
  }

  async function notifyPaid() {
    if (!browser || !guestData) return;
    try {
      await updateDoc(doc(db, "rooms", roomId, "guests", guestData.id), {
        status: "verifying"
      });
    } catch (e) {
      console.error("Error updating status:", e);
      alert("送信に失敗しました。");
    }
  }

  function openPayPay() {
    if (browser && roomData?.paypayUrl) {
      window.location.href = roomData.paypayUrl;
    }
  }

  async function updateMethod(newMethod: string) {
    if (!browser || !guestData) return;
    try {
      await updateDoc(doc(db, "rooms", roomId, "guests", guestData.id), {
        paymentMethod: newMethod
      });
      method = newMethod;
      showMethodModal = false;
      // URLを更新（ブラウザバック対策）
      const url = new URL(window.location.href);
      url.searchParams.set('method', newMethod);
      window.history.replaceState({}, '', url);
    } catch (e) {
      console.error("Error updating method:", e);
      alert("変更に失敗しました。");
    }
  }
</script>

<svelte:head>
  <title>支払い案内 - 飲みマネ</title>
</svelte:head>

<main class="max-w-md mx-auto px-6 py-12 flex flex-col min-h-screen">
  <div class="text-center mb-12">
    <div class="bg-green-50 text-green-500 w-20 h-20 rounded-full flex items-center justify-center mx-auto mb-6">
      <CheckCircle2 size={48} />
    </div>
    <h1 class="text-2xl font-black text-gray-800">チェックイン完了！</h1>
    <p class="text-gray-500 font-medium mt-2">幹事の画面に名前が表示されました。</p>
  </div>

  {#if roomData}
    <div class="flex-grow space-y-8">
      {#if guestData?.status === 'completed'}
        <div class="card bg-green-50 border-green-200 text-center py-12">
          <div class="bg-white w-20 h-20 rounded-full flex items-center justify-center mx-auto mb-6 shadow-sm">
            <CheckCircle2 size={48} class="text-green-500" />
          </div>
          <h2 class="text-2xl font-black text-green-700">お支払い完了！</h2>
          <p class="text-sm font-bold text-green-600 mt-2">幹事さんに承認されました。<br/>ありがとうございます！</p>
        </div>
      {:else if guestData?.status === 'verifying'}
        <div class="card bg-yellow-50 border-yellow-200 text-center py-12">
          <div class="animate-pulse bg-white w-20 h-20 rounded-full flex items-center justify-center mx-auto mb-6 shadow-sm">
            <Circle size={40} class="text-yellow-500" />
          </div>
          <h2 class="text-xl font-black text-yellow-700">確認待ちです...</h2>
          <p class="text-sm font-bold text-yellow-600 mt-2">幹事さんの承認を待っています。<br/>しばらくそのままでお待ちください。</p>
        </div>
      {:else}
        {#if method === 'paypay'}
          <div class="card space-y-4">
            <div class="text-center">
              <h2 class="text-lg font-black text-paypay-red">PayPayで支払う</h2>
              <div class="mt-2 mb-4 bg-red-50 py-3 rounded-2xl">
                <p class="text-[10px] text-gray-400 font-bold uppercase tracking-wider">あなたのお支払い額</p>
                <p class="text-3xl font-black text-paypay-red">¥{(guestData?.actualFee ?? roomData?.baseFee ?? 0).toLocaleString()}</p>
              </div>
            </div>
            <button on:click={openPayPay} class="btn-primary w-full flex items-center justify-center gap-2">
              PayPayを開く <ExternalLink size={18} />
            </button>
            <p class="text-[10px] text-gray-400 text-center leading-relaxed">
              ※ PayPayアプリが起動します。送金額を確認して送信してください。
            </p>
          </div>
        {:else if method === 'bank'}
          <div class="card space-y-4">
            <div class="text-center">
              <h2 class="text-lg font-black text-blue-600">銀行振込 / ことら送金</h2>
              <div class="mt-2 mb-4 bg-blue-50 py-3 rounded-2xl">
                <p class="text-[10px] text-gray-400 font-bold uppercase tracking-wider">あなたのお支払い額</p>
                <p class="text-3xl font-black text-blue-600">¥{(guestData?.actualFee ?? roomData?.baseFee ?? 0).toLocaleString()}</p>
              </div>
            </div>
            <div class="bg-blue-50 p-4 rounded-xl">
              <pre class="text-sm font-bold text-blue-800 whitespace-pre-wrap font-sans">{roomData.bankInfo || "振込送金情報は提供されていません。"}</pre>
            </div>
          </div>
        {:else}
          <div class="card space-y-4 text-center">
            <h2 class="text-lg font-black text-green-600">現金で支払う</h2>
            <div class="mt-2 mb-4 bg-green-50 py-3 rounded-2xl">
              <p class="text-[10px] text-gray-400 font-bold uppercase tracking-wider">あなたのお支払い額</p>
              <p class="text-3xl font-black text-green-600">¥{(guestData?.actualFee ?? roomData?.baseFee ?? 0).toLocaleString()}</p>
            </div>
            <div class="p-6 bg-green-50 rounded-2xl border-2 border-dashed border-green-200">
              <p class="text-sm font-bold text-green-700">
                準備ができたら<br/>幹事さんに渡してください
              </p>
            </div>
          </div>
        {/if}

        <div class="text-center">
          <button 
            on:click={() => showMethodModal = true}
            class="text-[10px] font-bold text-gray-400 border-b border-gray-200 pb-0.5 hover:text-paypay-red hover:border-paypay-red transition-all"
          >
            支払い方法を変更する
          </button>
        </div>

        <button 
          on:click={notifyPaid}
          class="w-full bg-gray-800 text-white font-black py-4 rounded-2xl shadow-xl shadow-gray-200 flex items-center justify-center gap-2 active:scale-[0.98] transition-all"
        >
          支払いました（幹事に通知）
        </button>
      {/if}
    </div>
  {:else}
    <div class="text-center text-gray-400">
      <p>情報を読み込み中...</p>
    </div>
  {/if}

  <footer class="mt-auto pt-10 pb-6 space-y-4 text-center">
    <button 
      on:click={leaveRoom} 
      class="text-xs font-bold text-gray-400 border border-gray-200 px-4 py-2 rounded-full hover:bg-gray-50 hover:text-gray-600 transition-all flex items-center justify-center gap-1 mx-auto"
    >
      <LogOut size={12} /> このルームから退出する
    </button>
    <button on:click={() => { if (browser) window.location.href = '/'; }} class="text-[10px] font-bold text-gray-300 hover:text-paypay-red transition-colors">
      トップページへ戻る
    </button>
  </footer>

  {#if showMethodModal}
    <div class="fixed inset-0 z-50 flex items-end sm:items-center justify-center p-0 sm:p-4">
      <!-- svelte-ignore a11y-click-events-have-key-events -->
      <!-- svelte-ignore a11y-no-static-element-interactions -->
      <div class="absolute inset-0 bg-black/40 backdrop-blur-sm" on:click={() => showMethodModal = false}></div>
      <div class="relative w-full max-w-md bg-white rounded-t-3xl sm:rounded-3xl shadow-2xl p-8 space-y-6 animate-in slide-in-from-bottom duration-300">
        <div class="flex items-center justify-between">
          <h2 class="text-xl font-black text-gray-800">支払い方法を変更</h2>
          <button on:click={() => showMethodModal = false} class="text-gray-400 hover:text-gray-600">
            <X size={24} />
          </button>
        </div>

        <div class="grid grid-cols-1 gap-3">
          <button
            on:click={() => updateMethod('paypay')}
            class="flex items-center justify-between p-4 rounded-xl border-2 transition-all {method === 'paypay' ? 'border-paypay-red bg-red-50' : 'border-gray-50 bg-gray-50'}"
          >
            <span class="font-bold {method === 'paypay' ? 'text-paypay-red' : 'text-gray-600'}">PayPay</span>
            {#if method === 'paypay'}
              <div class="w-5 h-5 rounded-full bg-paypay-red flex items-center justify-center">
                <div class="w-2 h-2 rounded-full bg-white"></div>
              </div>
            {/if}
          </button>

          <button
            on:click={() => updateMethod('bank')}
            class="flex items-center justify-between p-4 rounded-xl border-2 transition-all {method === 'bank' ? 'border-paypay-red bg-red-50' : 'border-gray-50 bg-gray-50'}"
          >
            <span class="font-bold {method === 'bank' ? 'text-paypay-red' : 'text-gray-600'}">銀行振込 / ことら送金</span>
            {#if method === 'bank'}
              <div class="w-5 h-5 rounded-full bg-paypay-red flex items-center justify-center">
                <div class="w-2 h-2 rounded-full bg-white"></div>
              </div>
            {/if}
          </button>

          <button
            on:click={() => updateMethod('cash')}
            class="flex items-center justify-between p-4 rounded-xl border-2 transition-all {method === 'cash' ? 'border-paypay-red bg-red-50' : 'border-gray-50 bg-gray-50'}"
          >
            <span class="font-bold {method === 'cash' ? 'text-paypay-red' : 'text-gray-600'}">現金</span>
            {#if method === 'cash'}
              <div class="w-5 h-5 rounded-full bg-paypay-red flex items-center justify-center">
                <div class="w-2 h-2 rounded-full bg-white"></div>
              </div>
            {/if}
          </button>
        </div>
      </div>
    </div>
  {/if}
</main>
