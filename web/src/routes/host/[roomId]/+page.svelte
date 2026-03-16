<script lang="ts">
  // @ts-nocheck
// @ts-ignore
  import { db } from "$lib/firebase";
// @ts-ignore
  import { doc, collection, onSnapshot, updateDoc, deleteDoc, query, orderBy } from "firebase/firestore";
// @ts-ignore
  import { page } from "$app/stores";
// @ts-ignore
  import { onMount } from "svelte";
// @ts-ignore
  import { browser } from "$app/environment";
// @ts-ignore
  import { goto } from "$app/navigation";
// @ts-ignore
  import QRCode from "svelte-qrcode";
// @ts-ignore
  import { Share2, CheckCircle2, Circle, User2, ChevronRight, Copy, Trash2, Settings, X } from "lucide-svelte";

  const roomId = $page.params.roomId;
  let roomData: any = null;
  let guests: any[] = [];
  let joinUrl = "";

  let showSettings = false;
  let editPayPayUrl = "";
  let editBankInfo = "";

  onMount(() => {
    if (typeof window !== "undefined") {
      joinUrl = `${window.location.protocol}//${window.location.host}/join/${roomId}`;
    }

    // Subscribe to Room Data
    const unsubRoom = onSnapshot(doc(db, "rooms", roomId), (doc) => {
      roomData = doc.data();
      if (roomData && !showSettings) {
        editPayPayUrl = roomData.paypayUrl || "";
        editBankInfo = roomData.bankInfo || "";
      }
    });

    // Subscribe to Guests
    const q = query(collection(db, "rooms", roomId, "guests"), orderBy("joinedAt", "desc"));
    const unsubGuests = onSnapshot(q, (snapshot) => {
      guests = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
    });

    return () => {
      unsubRoom();
      unsubGuests();
    };
  });

  async function toggleStatus(guestId: string, currentStatus: string) {
    const newStatus = currentStatus === "waiting" ? "completed" : "waiting";
    await updateDoc(doc(db, "rooms", roomId, "guests", guestId), {
      status: newStatus
    });
  }

  async function approvePayment(guestId: string) {
    if (!browser) return;
    try {
      await updateDoc(doc(db, "rooms", roomId, "guests", guestId), {
        status: "completed"
      });
    } catch (e) {
      console.error("Error approving payment:", e);
    }
  }

  function copyUrl() {
    if (browser) {
      navigator.clipboard.writeText(joinUrl);
    }
  }

  $: totalCollected = guests
    .filter(g => g.status === "completed")
    .reduce((sum, g) => sum + (g.actualFee || roomData?.baseFee || 0), 0);
  
  $: totalExpected = guests.length * (roomData?.baseFee || 0);

  async function updateGuestAmount(guestId: string, amount: number) {
    if (!browser) return;
    try {
      await updateDoc(doc(db, "rooms", roomId, "guests", guestId), {
        actualFee: Number(amount)
      });
    } catch (e) {
      console.error("Error updating amount:", e);
    }
  }

  function getMethodIcon(method: string) {
    switch (method) {
      case "paypay": return "P";
      case "bank": return "🏦";
      case "cash": return "💵";
      default: return "?";
    }
  }
  async function deleteRoom() {
    if (!browser) return;

    if (confirm("本当にルームを削除して終了しますか？参加者も強制退出になります。")) {
      try {
        await deleteDoc(doc(db, "rooms", roomId));
        goto("/");
      } catch (e) {
        console.error("Error deleting room:", e);
        alert("削除に失敗しました。");
      }
    }
  }

  let copied = false;
  $: isAllCompleted = guests.length > 0 && guests.every(g => g.status === 'completed');

  async function copyReport() {
    if (!browser) return;
    
    const text = `【集金完了のお知らせ】
本日はお疲れ様でした！無事に集金が完了しました。

💰 総集金額: ${totalCollected.toLocaleString()}円（目標: ${totalExpected.toLocaleString()}円）
👥 参加人数: ${guests.length}名

ご協力ありがとうございました！🍻`;

    try {
      await navigator.clipboard.writeText(text);
      copied = true;
      setTimeout(() => { copied = false; }, 2000);
    } catch (e) {
      console.error("Failed to copy report:", e);
    }
  }

  async function saveSettings() {
    if (!browser) return;
    try {
      await updateDoc(doc(db, "rooms", roomId), {
        paypayUrl: editPayPayUrl,
        bankInfo: editBankInfo
      });
      showSettings = false;
    } catch (e) {
      console.error("Error saving settings:", e);
      alert("保存に失敗しました。");
    }
  }
</script>

<svelte:head>
  <title>幹事ダッシュボード - 飲みマネ</title>
</svelte:head>

<main class="max-w-xl mx-auto px-4 py-8 bg-paypay-lightGray min-h-screen">
  <header class="flex items-center justify-between mb-6 px-2">
    <div>
      <h1 class="text-xl font-black text-gray-800 italic">Dashboard</h1>
      {#if roomData}
        <p class="text-[10px] font-bold text-gray-400">幹事: {roomData.hostName}</p>
      {/if}
    </div>
    <div class="flex items-center gap-3">
      <button 
        on:click={() => {
          editPayPayUrl = roomData?.paypayUrl || "";
          editBankInfo = roomData?.bankInfo || "";
          showSettings = true;
        }}
        class="w-8 h-8 rounded-full bg-white shadow-sm flex items-center justify-center text-gray-400 hover:text-paypay-red transition-all"
      >
        <Settings size={18} />
      </button>
      <div class="bg-paypay-red text-white text-[10px] font-bold px-2 py-1 rounded-full animate-pulse">
        リアルタイム更新中
      </div>
    </div>
  </header>

  {#if roomData}
    <div class="space-y-6 pb-32">
      <!-- 集金ステータス -->
      <section class="bg-white p-6 rounded-3xl shadow-sm">
        <div class="flex justify-between items-end mb-4">
          <div>
            <p class="text-[10px] font-bold text-gray-400 mb-1">現在の回収額</p>
            <div class="flex items-baseline gap-1">
              <span class="text-4xl font-black text-paypay-red">{totalCollected.toLocaleString()}</span>
              <span class="text-sm font-bold text-gray-400">円</span>
            </div>
          </div>
          <div class="text-right">
            <p class="text-[10px] font-bold text-gray-400 mb-1">目標額</p>
            <p class="text-lg font-bold text-gray-700">{totalExpected.toLocaleString()} 円</p>
          </div>
        </div>
        <div class="w-full bg-gray-100 h-2 rounded-full overflow-hidden">
          <div class="bg-paypay-red h-full transition-all duration-500" style="width: {totalExpected > 0 ? (totalCollected / totalExpected) * 100 : 0}%"></div>
        </div>

        <button 
          on:click={copyReport}
          class="w-full mt-6 py-4 rounded-2xl font-black text-sm flex items-center justify-center gap-2 transition-all shadow-lg active:scale-95 {isAllCompleted ? 'bg-green-500 text-white shadow-green-100' : 'bg-white border-2 border-gray-100 text-gray-400'}"
        >
          {#if copied}
            <CheckCircle2 size={18} /> ✅ コピーしました！
          {:else}
            <Share2 size={18} /> 結果をコピーして共有
          {/if}
        </button>
      </section>

      <!-- 招待QR -->
      <section class="bg-white p-6 rounded-3xl shadow-sm text-center">
        <p class="text-sm font-bold text-gray-700 mb-4">参加はこちらから！</p>
        <div class="inline-block p-4 bg-white border-4 border-paypay-red rounded-2xl mb-4">
          {#if joinUrl}
            <QRCode value={joinUrl} size={180} />
          {/if}
        </div>
        <div class="flex gap-2">
          <button on:click={copyUrl} class="flex-1 bg-gray-100 text-gray-700 font-bold py-3 rounded-xl flex items-center justify-center gap-2 text-sm">
            <Copy size={16} /> リンクをコピー
          </button>
        </div>
      </section>

      <!-- 参加者リスト -->
      <section class="space-y-3">
        <div class="flex items-center justify-between px-2">
          <h2 class="font-bold text-gray-700">参加者リスト ({guests.length}名)</h2>
        </div>

        {#each guests as guest}
          <div class="bg-white p-4 rounded-2xl shadow-sm border-2 transition-all {guest.status === 'verifying' ? 'border-yellow-400 bg-yellow-50' : 'border-transparent'} {guest.status === 'completed' ? 'opacity-60' : ''} flex items-center justify-between group">
            <div class="flex items-center gap-4">
              <div class="w-12 h-12 rounded-full flex items-center justify-center text-xl {guest.status === 'completed' ? 'bg-green-100 text-green-500' : (guest.status === 'verifying' ? 'bg-yellow-100 text-yellow-500' : 'bg-gray-100 text-gray-400')}">
                {#if guest.status === 'completed'}
                  <CheckCircle2 size={24} />
                {:else if guest.status === 'verifying'}
                  <div class="animate-pulse"><Circle size={24} /></div>
                {:else}
                  <User2 size={24} />
                {/if}
              </div>
              <div>
                <div class="flex items-center gap-2">
                  <p class="font-bold text-gray-800">{guest.name}</p>
                  {#if guest.status === 'verifying'}
                    <span class="text-[8px] bg-yellow-400 text-white px-1.5 py-0.5 rounded-full font-black animate-bounce uppercase">確認依頼</span>
                  {/if}
                </div>
                <div class="flex items-center gap-2 mt-0.5">
                  <span class="text-[10px] font-bold px-1.5 py-0.5 rounded bg-gray-100 text-gray-500 uppercase">{guest.paymentMethod}</span>
                  <div class="flex items-center gap-1">
                    <span class="text-[10px] font-bold text-gray-400">請求額: ¥</span>
                    <input
                      type="number"
                      value={guest.actualFee || roomData.baseFee}
                      on:blur={(e) => updateGuestAmount(guest.id, e.target.value)}
                      disabled={guest.status === 'completed'}
                      class="w-20 px-2 py-0.5 bg-gray-50 border border-gray-100 rounded text-xs font-black text-paypay-red outline-none focus:border-paypay-red transition-colors disabled:opacity-50"
                    />
                  </div>
                </div>
              </div>
            </div>
            
            {#if guest.status === 'completed'}
              <div class="text-green-500 font-bold text-sm flex items-center gap-1 pr-2">
                <CheckCircle2 size={16} /> 完了
              </div>
            {:else if guest.status === 'verifying'}
              <button 
                on:click={() => approvePayment(guest.id)}
                class="px-5 py-2.5 bg-yellow-400 text-white rounded-full font-black text-xs shadow-lg shadow-yellow-200 active:scale-95 transition-all"
              >
                承認する
              </button>
            {:else}
              <div class="text-[10px] font-bold text-gray-300 pr-2">支払い待ち</div>
            {/if}
          </div>
        {:else}
          <div class="text-center py-12 text-gray-400">
            <p class="text-sm font-medium">参加者を待っています...</p>
          </div>
        {/each}
      </section>

      <footer class="pt-8">
        <button 
          on:click={deleteRoom}
          class="w-full py-4 rounded-2xl border-2 border-paypay-red text-paypay-red font-bold flex items-center justify-center gap-2 bg-white hover:bg-paypay-red/5 transition-colors"
        >
          <Trash2 size={20} /> ルームを終了・削除する
        </button>
      </footer>
    </div>
  {:else}
    <div class="flex flex-col items-center justify-center h-64 text-gray-400">
      <div class="animate-spin text-3xl mb-4">🌀</div>
      <p class="text-sm font-medium">データを読み込み中...</p>
    </div>
  {/if}

  {#if showSettings}
    <div class="fixed inset-0 z-50 flex items-end sm:items-center justify-center p-0 sm:p-4">
      <!-- svelte-ignore a11y-click-events-have-key-events -->
      <!-- svelte-ignore a11y-no-static-element-interactions -->
      <div class="absolute inset-0 bg-black/40 backdrop-blur-sm" on:click={() => showSettings = false}></div>
      <div class="relative w-full max-w-md bg-white rounded-t-3xl sm:rounded-3xl shadow-2xl p-8 space-y-6 animate-in slide-in-from-bottom duration-300">
        <div class="flex items-center justify-between">
          <h2 class="text-xl font-black text-gray-800">ルーム設定</h2>
          <button on:click={() => showSettings = false} class="text-gray-400 hover:text-gray-600">
            <X size={24} />
          </button>
        </div>

        <div class="space-y-4">
          <label class="block">
            <span class="text-xs font-bold text-gray-500 ml-1">PayPay マイコードURL</span>
            <input
              type="url"
              bind:value={editPayPayUrl}
              placeholder="https://paypay.ne.jp/..."
              class="mt-1 block w-full px-4 py-3 bg-gray-50 border-none rounded-xl focus:ring-2 focus:ring-paypay-red focus:bg-white transition-all outline-none text-sm"
            />
          </label>

          <label class="block">
            <span class="text-xs font-bold text-gray-500 ml-1">銀行口座 / ことら送金</span>
            <textarea
              bind:value={editBankInfo}
              rows="4"
              placeholder="振込先情報を入力"
              class="mt-1 block w-full px-4 py-3 bg-gray-50 border-none rounded-xl focus:ring-2 focus:ring-paypay-red focus:bg-white transition-all outline-none text-sm"
            ></textarea>
          </label>
        </div>

        <button 
          on:click={saveSettings}
          class="btn-primary w-full py-4 text-sm"
        >
          保存する
        </button>
      </div>
    </div>
  {/if}
</main>
